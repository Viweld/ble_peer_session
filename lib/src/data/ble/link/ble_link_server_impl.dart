import 'dart:async';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/services.dart';

import '../../../config/ble_peer_config.dart';
import '../../../domain/exceptions/peer_exception.dart';
import '../../../domain/logger/logger.dart';
import '../../../domain/transport/transport_link_server.dart';
import '../platform/android_peripheral_shutdown.dart';
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
  PeripheralManager? _peripheralManager;
  GATTCharacteristic? _writeCharacteristic;
  StreamSubscription<GATTCharacteristicWriteRequestedEventArgs>? _writeRequestSubscription;
  StreamSubscription<CentralConnectionStateChangedEventArgs>? _connectionStateSubscription;
  StreamSubscription<GATTCharacteristicNotifyStateChangedEventArgs>? _notifyStateSubscription;
  final Map<String, Central> _connectedClients = {};

  PeripheralManager get _peripheral => _peripheralManager ??= PeripheralManager();

  @override
  bool get isPhysicallyConnected => _connectedClients.isNotEmpty;

  @override
  Future<void> startAdvertisingAs({required String deviceName}) async {
    try {
      await BleLinkReadiness.ensurePermissions();
      await BleLinkReadiness.ensureManagerPoweredOn(_peripheral);
      await stopAdvertising();
      await _peripheral.removeAllServices();

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

      await _peripheral.addService(service);

      _writeRequestSubscription = _peripheral.characteristicWriteRequested.listen(
        _peripheralEventHandler,
      );

      _connectionStateSubscription = _peripheral.connectionStateChanged.listen((event) {
        if (event.state != ConnectionState.disconnected) return;
        final String centralId = event.central.uuid.toString();
        if (!_connectedClients.containsKey(centralId)) return;
        _handleGattDisconnected();
      });

      _notifyStateSubscription = _peripheral.characteristicNotifyStateChanged.listen((event) {
        if (event.state) return;
        if (event.characteristic.uuid != super.characteristicUuid) return;
        final String centralId = event.central.uuid.toString();
        if (!_connectedClients.containsKey(centralId)) return;
        _handleGattDisconnected();
      });

      await _peripheral.startAdvertising(
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
    if (_peripheralManager == null) return;

    try {
      await _peripheral.stopAdvertising();
      await _writeRequestSubscription?.cancel();
      _writeRequestSubscription = null;
      await _connectionStateSubscription?.cancel();
      _connectionStateSubscription = null;
      await _notifyStateSubscription?.cancel();
      _notifyStateSubscription = null;
    } catch (e) {
      _log.e('Failed to stop advertising: $e');
    }
  }

  @override
  Future<void> sendPhysicalFrame(Uint8List frame) async {
    if (_connectedClients.isEmpty || _writeCharacteristic == null) {
      _log.w('No connected centrals to notify');
      return;
    }

    for (final client in _connectedClients.entries) {
      try {
        await _peripheral.notifyCharacteristic(client.value, _writeCharacteristic!, value: frame);
      } catch (e) {
        _log.e('Failed to notify central ${client.key}: $e');
      }
    }
  }

  @override
  Future<void> disconnect() async {
    beginIntentionalDisconnect();
    _connectedClients.clear();
    resetIntentionalDisconnect();
  }

  @override
  Future<void> onDispose() async {
    await _writeRequestSubscription?.cancel();
    await _connectionStateSubscription?.cancel();
    await _notifyStateSubscription?.cancel();
    await _shutdownPeripheralStack();
    beginIntentionalDisconnect();
    _connectedClients.clear();
    resetIntentionalDisconnect();
  }

  void _handleGattDisconnected() {
    if (intentionalDisconnect) return;
    _connectedClients.clear();
    emitLinkLost();
  }

  Future<void> _shutdownPeripheralStack() async {
    if (_peripheralManager == null) return;

    await stopAdvertising();
    try {
      await _peripheral.removeAllServices();
    } catch (e) {
      _log.e('Failed to remove GATT services: $e');
    }
    await closeAndroidGattServer();
    _peripheralManager = null;
  }

  Future<void> _peripheralEventHandler(GATTCharacteristicWriteRequestedEventArgs event) async {
    final clientId = event.central.uuid.toString();

    if (!_connectedClients.containsKey(clientId)) {
      // 1:1 only — reject a second central with insufficientResources.
      if (_connectedClients.isNotEmpty) {
        await _peripheral.respondWriteRequestWithError(
          event.request,
          error: GATTError.insufficientResources,
        );
        return;
      }
      _connectedClients[clientId] = event.central;
    }

    translateIncomingData(event.request.value);
    await _peripheral.respondWriteRequest(event.request);
  }
}
