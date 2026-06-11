import 'dart:async';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/services.dart';

import '../../../config/ble_peer_config.dart';
import '../../../domain/exceptions/bluetooth_exceptions.dart';
import '../../../domain/logger/logger.dart';
import '../../../domain/transport/transport_link_server.dart';
import 'ble_link_base.dart';

final class BleLinkServerImpl extends BleLinkBase
    implements TransportLinkServer {
  BleLinkServerImpl({
    required Logger logger,
    required BlePeerConfig config,
  }) : _log = logger,
       super(
         appName: config.appName,
         serviceId: config.serviceUuid,
         characteristicId: config.characteristicUuid,
       );

  final Logger _log;
  final _peripheralManager = PeripheralManager();
  GATTCharacteristic? _writeCharacteristic;
  StreamSubscription<GATTCharacteristicWriteRequestedEventArgs>?
  _writeRequestSubscription;
  final Map<String, Central> _connectedClients = {};

  @override
  Future<void> startAdvertisingAs({required String deviceName}) async {
    try {
      await stopAdvertising();

      _writeCharacteristic = GATTCharacteristic.mutable(
        uuid: super.characteristicUuid,
        properties: [
          GATTCharacteristicProperty.read,
          GATTCharacteristicProperty.write,
          GATTCharacteristicProperty.notify,
        ],
        permissions: [
          GATTCharacteristicPermission.read,
          GATTCharacteristicPermission.write,
        ],
        descriptors: [],
      );

      final service = GATTService(
        uuid: super.serviceUuid,
        isPrimary: true,
        includedServices: [],
        characteristics: [_writeCharacteristic!],
      );

      await _peripheralManager.addService(service);

      _writeRequestSubscription = _peripheralManager
          .characteristicWriteRequested
          .listen(_peripheralEventHandler);

      await _peripheralManager.startAdvertising(
        Advertisement(name: deviceName, serviceUUIDs: [super.serviceUuid]),
      );
    } on Object catch (e) {
      _log.e('Ошибка запуска рекламы: $e');
      if (e is PlatformException && e.code.contains('IllegalStateException')) {
        throw BluetoothDisabledException();
      }
      rethrow;
    }
  }

  @override
  Future<void> stopAdvertising() async {
    try {
      await _peripheralManager.stopAdvertising();
      await _writeRequestSubscription?.cancel();
      _writeRequestSubscription = null;
    } catch (e) {
      _log.e('Ошибка остановки рекламы: $e');
    }
  }

  @override
  Future<void> sendRawMessage(Uint8List data) async {
    if (_connectedClients.isEmpty || _writeCharacteristic == null) {
      _log.w('Нет подключённых клиентов для уведомления');
      return;
    }

    for (final client in _connectedClients.entries) {
      try {
        await _peripheralManager.notifyCharacteristic(
          client.value,
          _writeCharacteristic!,
          value: data,
        );
      } catch (e) {
        _log.e('Ошибка уведомления клиента ${client.key}: $e');
      }
    }
  }

  @override
  Future<void> disconnect() async {
    _connectedClients.clear();
  }

  @override
  Future<void> onDispose() async {
    await _writeRequestSubscription?.cancel();
    await stopAdvertising();
    await disconnect();
  }

  Future<void> _peripheralEventHandler(
    GATTCharacteristicWriteRequestedEventArgs event,
  ) async {
    final clientId = event.central.uuid.toString();

    if (!_connectedClients.containsKey(clientId)) {
      if (_connectedClients.isNotEmpty) {
        await _peripheralManager.respondWriteRequestWithError(
          event.request,
          error: GATTError.insufficientResources,
        );
        return;
      }
      _connectedClients[clientId] = event.central;
    }

    translateIncomingData(event.request.value);
    await _peripheralManager.respondWriteRequest(event.request);
  }
}
