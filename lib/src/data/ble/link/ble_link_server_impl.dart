import 'dart:async';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/services.dart';

import '../../../config/ble_peer_config.dart';
import '../../../domain/exceptions/peer_exception.dart';
import '../../../domain/logger/logger.dart';
import '../../../domain/transport/transport_link_server.dart';
import 'ble_link_base.dart';
import 'ble_link_readiness.dart';

final class BleLinkServerImpl extends BleLinkBase implements TransportLinkServer {
  BleLinkServerImpl({required Logger logger, required BlePeerConfig config})
    : _log = logger,
      super(
        appName: config.appName,
        serviceId: config.serviceUuid,
        characteristicId: config.characteristicUuid,
      );

  final Logger _log;
  final _peripheralManager = PeripheralManager();
  GATTCharacteristic? _writeCharacteristic;
  StreamSubscription<GATTCharacteristicWriteRequestedEventArgs>? _writeRequestSubscription;
  final Map<String, Central> _connectedClients = {};

  @override
  Future<void> startAdvertisingAs({required String deviceName}) async {
    try {
      await BleLinkReadiness.ensurePermissions();
      await BleLinkReadiness.ensureManagerPoweredOn(_peripheralManager);
      await stopAdvertising();
      await _peripheralManager.removeAllServices();

      _writeCharacteristic = GATTCharacteristic.mutable(
        uuid: super.characteristicUuid,
        properties: [
          GATTCharacteristicProperty.read,
          GATTCharacteristicProperty.write,
          GATTCharacteristicProperty.notify,
        ],
        permissions: [GATTCharacteristicPermission.read, GATTCharacteristicPermission.write],
        descriptors: [],
      );

      final service = GATTService(
        uuid: super.serviceUuid,
        isPrimary: true,
        includedServices: [],
        characteristics: [_writeCharacteristic!],
      );

      await _peripheralManager.addService(service);

      _writeRequestSubscription = _peripheralManager.characteristicWriteRequested.listen(
        _peripheralEventHandler,
      );

      await _peripheralManager.startAdvertising(
        Advertisement(name: deviceName, serviceUUIDs: [super.serviceUuid]),
      );
    } on PeerException {
      rethrow;
    } on Object catch (e) {
      _log.e('Failed to start advertising: $e');
      if (e is PlatformException && e.code.contains('IllegalStateException')) {
        throwPeer(PeerErrorCode.peripheralUnavailable, cause: e);
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
      _log.e('Failed to stop advertising: $e');
    }
  }

  @override
  Future<void> sendRawMessage(Uint8List data) async {
    if (_connectedClients.isEmpty || _writeCharacteristic == null) {
      _log.w('No connected centrals to notify');
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
        _log.e('Failed to notify central ${client.key}: $e');
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

  Future<void> _peripheralEventHandler(GATTCharacteristicWriteRequestedEventArgs event) async {
    final clientId = event.central.uuid.toString();

    if (!_connectedClients.containsKey(clientId)) {
      // 1:1 only — reject a second central with insufficientResources.
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
