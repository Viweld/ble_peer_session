import 'dart:async';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

import '../../../config/ble_peer_config.dart';
import '../../../domain/exceptions/peer_exception.dart';
import '../../../domain/logger/logger.dart';
import '../../../domain/models/device.dart';
import '../../../domain/transport/transport_link_client.dart';
import '../../../platform/ble_session_retention.dart';
import '../discovery/ble_discovery_registry.dart';
import 'ble_gatt_write_policy.dart';
import 'ble_link_base.dart';
import 'ble_link_readiness.dart';

final class BleLinkClientImpl extends BleLinkBase
    implements TransportLinkClient {
  BleLinkClientImpl({
    required Logger logger,
    required BlePeerConfig config,
    BleSessionRetention retention = const NoOpBleSessionRetention(),
    int Function()? elapsedMs,
  }) : _log = logger,
       _deviceNamePrefix = config.deviceNamePrefix,
       _retention = retention,
       super(
         appName: config.appName,
         serviceId: config.serviceUuid,
         characteristicId: config.characteristicUuid,
       ) {
    _discoveredDevicesController = StreamController<List<Device>>.broadcast();
    final Stopwatch clock = Stopwatch()..start();
    _discoveryRegistry = BleDiscoveryRegistry(
      staleAfter: config.discoveryStaleAfter,
      sweepInterval: config.discoverySweepInterval,
      elapsedMs: elapsedMs ?? () => clock.elapsedMilliseconds,
      emit: _emitDiscoveredSnapshot,
    );
  }

  final Logger _log;
  final String _deviceNamePrefix;
  final BleSessionRetention _retention;
  final _centralManager = CentralManager();
  late final StreamController<List<Device>> _discoveredDevicesController;
  late final BleDiscoveryRegistry _discoveryRegistry;
  final Map<String, Peripheral> _discoveredPeripherals = {};
  Peripheral? _connectedPeripheral;
  Peripheral? _connectingPeripheral;
  GATTCharacteristic? _writeCharacteristic;
  int _connectGeneration = 0;
  bool _connectCancelled = false;
  bool _sessionRetained = false;

  StreamSubscription<DiscoveredEventArgs>? _scanSubscription;
  StreamSubscription<GATTCharacteristicNotifiedEventArgs>? _dataSubscription;
  StreamSubscription<PeripheralConnectionStateChangedEventArgs>?
  _connectionStateSubscription;

  @override
  bool get isPhysicallyConnected => _connectedPeripheral != null;

  @override
  Stream<List<Device>> get discoveredDevicesStream =>
      _discoveredDevicesController.stream;

  @override
  Future<void> startDiscovery() async {
    try {
      await BleLinkReadiness.ensurePermissions();
      await BleLinkReadiness.ensureManagerPoweredOn(_centralManager);
      await stopDiscovery();
      _discoveredPeripherals.clear();
      _discoveryRegistry.beginGeneration();
      _log.d('Starting BLE device scan');

      _scanSubscription = _centralManager.discovered.listen((event) {
        _processDiscoveredDevice(event.peripheral, event.advertisement);
      });

      await _centralManager.startDiscovery(serviceUUIDs: [super.serviceUuid]);
    } on PeerException {
      rethrow;
    } on Object catch (e, stackTrace) {
      _log.e('Failed to start discovery: $e');
      throwPeer(
        PeerErrorCode.discoveryFailed,
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> stopDiscovery() async {
    try {
      await _centralManager.stopDiscovery();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
    } catch (e) {
      _log.e('Failed to stop discovery: $e');
    }
    _discoveryRegistry.stop();
    _discoveredPeripherals.clear();
  }

  @override
  Future<void> refreshDiscovery() async {
    await stopDiscovery();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await startDiscovery();
  }

  @override
  Future<void> connectToDevice(Device device) async {
    final peripheral = _discoveredPeripherals[device.id];
    if (peripheral == null) {
      throwPeer(PeerErrorCode.deviceNotFound);
    }

    final int generation = _beginConnect(peripheral);
    try {
      resetIntentionalDisconnect();
      await _retention.retain();
      _sessionRetained = true;
      _connectionStateSubscription = _centralManager.connectionStateChanged
          .listen((event) {
            final Peripheral? connected = _connectedPeripheral;
            if (connected == null) return;
            if (event.peripheral.uuid != connected.uuid) return;
            if (event.state == ConnectionState.disconnected) {
              _handleGattDisconnected();
            }
          });

      await _centralManager.connect(peripheral);
      _ensureConnectCurrent(generation);
      _connectedPeripheral = peripheral;

      final services = await _centralManager.discoverGATT(peripheral);
      _ensureConnectCurrent(generation);

      var serviceFound = false;
      for (final service in services) {
        if (service.uuid != super.serviceUuid) continue;
        serviceFound = true;

        for (final characteristic in service.characteristics) {
          if (characteristic.uuid != super.characteristicUuid) continue;

          if (characteristic.properties.contains(
            GATTCharacteristicProperty.notify,
          )) {
            await _centralManager.setCharacteristicNotifyState(
              peripheral,
              characteristic,
              state: true,
            );
            _ensureConnectCurrent(generation);
            _dataSubscription = _centralManager.characteristicNotified
                .where(
                  (args) =>
                      args.characteristic.uuid == super.characteristicUuid,
                )
                .listen((event) => translateIncomingData(event.value));
          }

          if (characteristic.properties.contains(
                GATTCharacteristicProperty.write,
              ) ||
              characteristic.properties.contains(
                GATTCharacteristicProperty.writeWithoutResponse,
              )) {
            _writeCharacteristic = characteristic;
          }
        }
        break;
      }

      if (!serviceFound) {
        throwPeer(PeerErrorCode.serviceNotFound);
      }

      await _centralManager
          .requestMTU(peripheral, mtu: 512)
          .catchError((_) => 0);
      _ensureConnectCurrent(generation);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _ensureConnectCurrent(generation);
    } on PeerException {
      await _failConnect();
      rethrow;
    } on Object catch (e, stackTrace) {
      await _failConnect();
      if (_isCancelled(generation)) {
        throwPeer(
          PeerErrorCode.operationCancelled,
          cause: e,
          stackTrace: stackTrace,
        );
      }
      throwPeer(
        PeerErrorCode.connectionFailed,
        cause: e,
        stackTrace: stackTrace,
      );
    } finally {
      if (generation == _connectGeneration) {
        _connectingPeripheral = null;
      }
    }
  }

  @override
  Future<void> cancelPendingConnection() async {
    _connectCancelled = true;
    _connectGeneration++;
    final Peripheral? peripheral =
        _connectingPeripheral ?? _connectedPeripheral;
    if (peripheral == null) return;

    beginIntentionalDisconnect();
    try {
      await _centralManager.disconnect(peripheral);
    } catch (e) {
      _log.e('Failed to cancel pending connection: $e');
    }
    await _clearConnectionState();
    await _releaseRetention();
    resetIntentionalDisconnect();
  }

  @override
  Future<void> sendPhysicalFrame(Uint8List frame) async {
    if (_connectedPeripheral == null || _writeCharacteristic == null) {
      throwPeer(PeerErrorCode.sessionNotConnected);
    }

    Object? lastError;
    StackTrace? lastStackTrace;

    for (
      int attempt = 1;
      attempt <= BleGattWritePolicy.maxAttempts;
      attempt++
    ) {
      try {
        await _centralManager.writeCharacteristic(
          _connectedPeripheral!,
          _writeCharacteristic!,
          value: frame,
          type: GATTCharacteristicWriteType.withoutResponse,
        );
        return;
      } on Object catch (e, stackTrace) {
        lastError = e;
        lastStackTrace = stackTrace;

        if (BleGattWritePolicy.shouldRetryWrite(attempt: attempt, error: e)) {
          _log.w(
            'Transient GATT write failure '
            '(attempt $attempt/${BleGattWritePolicy.maxAttempts}): $e',
          );
          await Future<void>.delayed(BleGattWritePolicy.retryDelay * attempt);
          continue;
        }

        _log.e(
          'Failed to send data (attempt $attempt/${BleGattWritePolicy.maxAttempts}): $e',
        );
        if (BleGattWritePolicy.isGattLinkLostError(e)) {
          await _resetConnection();
        }
        throwPeer(
          PeerErrorCode.messageSendFailed,
          cause: e,
          stackTrace: stackTrace,
        );
      }
    }

    throwPeer(
      PeerErrorCode.messageSendFailed,
      cause: lastError,
      stackTrace: lastStackTrace,
    );
  }

  @override
  Future<void> disconnect() async {
    beginIntentionalDisconnect();
    await _clearConnectionState();
    await _releaseRetention();
    resetIntentionalDisconnect();
  }

  @override
  Future<void> onDispose() async {
    _discoveryRegistry.dispose();
    await _discoveredDevicesController.close();
    await _scanSubscription?.cancel();
    await _dataSubscription?.cancel();
    await _connectionStateSubscription?.cancel();
    try {
      await _centralManager.stopDiscovery();
    } catch (e) {
      _log.e('Failed to stop discovery: $e');
    }
    beginIntentionalDisconnect();
    await _clearConnectionState();
    await _releaseRetention();
  }

  void _handleGattDisconnected() {
    if (intentionalDisconnect) return;
    unawaited(_clearConnectionState());
    unawaited(_releaseRetention());
    emitLinkLost();
  }

  Future<void> _clearConnectionState() async {
    await _dataSubscription?.cancel();
    _dataSubscription = null;
    await _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;

    final Peripheral? peripheral =
        _connectedPeripheral ?? _connectingPeripheral;
    _connectedPeripheral = null;
    _connectingPeripheral = null;
    _writeCharacteristic = null;

    if (peripheral == null) return;
    try {
      await _centralManager.disconnect(peripheral);
    } catch (e) {
      _log.e('Failed to disconnect: $e');
    }
  }

  bool _isOurApplication(Advertisement advertisement) {
    if (advertisement.name?.contains(super.appName) == true) return true;
    if (advertisement.serviceUUIDs.contains(super.serviceUuid)) return true;

    for (final data in advertisement.manufacturerSpecificData) {
      if (data.id == 0x0499 &&
          data.data.length >= 3 &&
          data.data[0] == 0x01 &&
          data.data[1] == 0x02 &&
          data.data[2] == 0x03) {
        return true;
      }
    }
    return false;
  }

  void _processDiscoveredDevice(
    Peripheral peripheral,
    Advertisement advertisement,
  ) {
    final bool isOurApp = _isOurApplication(advertisement);
    if (!isOurApp) return;

    final deviceName = advertisement.name ?? peripheral.uuid.toString();
    final deviceId = peripheral.uuid.toString();
    _discoveredPeripherals[deviceId] = peripheral;
    var cleanName = _getCleanDeviceName(deviceName, super.appName);
    if (_deviceNamePrefix.isNotEmpty) {
      cleanName = cleanName.replaceFirst(_deviceNamePrefix, '');
    }
    _discoveryRegistry.observe(
      Device(id: deviceId, name: cleanName, isOurApp: true),
    );
  }

  void _emitDiscoveredSnapshot(List<Device> devices) {
    if (_discoveredDevicesController.isClosed) return;
    final Set<String> liveIds = devices
        .map((Device device) => device.id)
        .toSet();
    _discoveredPeripherals.removeWhere((String id, _) => !liveIds.contains(id));
    _discoveredDevicesController.add(devices);
  }

  String _getCleanDeviceName(String deviceName, String appName) {
    if (!deviceName.contains(appName)) return deviceName;
    var cleanName = deviceName
        .replaceAll(appName, '')
        .replaceAll('🎮', '')
        .trim();
    return cleanName.startsWith('-')
        ? cleanName.substring(1).trim()
        : cleanName;
  }

  Future<void> _resetConnection() async {
    beginIntentionalDisconnect();
    await _clearConnectionState();
    await _releaseRetention();
    resetIntentionalDisconnect();
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  int _beginConnect(Peripheral peripheral) {
    _connectCancelled = false;
    _connectGeneration++;
    _connectingPeripheral = peripheral;
    return _connectGeneration;
  }

  void _ensureConnectCurrent(int generation) {
    if (_isCancelled(generation)) {
      throwPeer(PeerErrorCode.operationCancelled);
    }
  }

  bool _isCancelled(int generation) {
    return _connectCancelled || generation != _connectGeneration;
  }

  Future<void> _failConnect() async {
    await _clearConnectionState();
    await _releaseRetention();
  }

  Future<void> _releaseRetention() async {
    if (!_sessionRetained) return;
    _sessionRetained = false;
    await _retention.release();
  }
}
