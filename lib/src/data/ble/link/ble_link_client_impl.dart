import 'dart:async';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

import '../../../config/ble_peer_config.dart';
import '../../../domain/exceptions/peer_exception.dart';
import '../../../domain/logger/logger.dart';
import '../../../domain/models/device.dart';
import '../../../domain/transport/transport_link_client.dart';
import 'ble_link_base.dart';
import 'ble_link_readiness.dart';

final class BleLinkClientImpl extends BleLinkBase implements TransportLinkClient {
  BleLinkClientImpl({required Logger logger, required BlePeerConfig config})
    : _log = logger,
      _deviceNamePrefix = config.deviceNamePrefix,
      super(
        appName: config.appName,
        serviceId: config.serviceUuid,
        characteristicId: config.characteristicUuid,
      ) {
    _discoveredDevicesController = StreamController<List<Device>>.broadcast();
  }

  final Logger _log;
  final String _deviceNamePrefix;
  final _centralManager = CentralManager();
  late final StreamController<List<Device>> _discoveredDevicesController;
  final List<Device> _foundDevices = [];
  final Map<String, Peripheral> _discoveredPeripherals = {};
  Peripheral? _connectedPeripheral;
  GATTCharacteristic? _writeCharacteristic;

  StreamSubscription<DiscoveredEventArgs>? _scanSubscription;
  StreamSubscription<GATTCharacteristicNotifiedEventArgs>? _dataSubscription;
  StreamSubscription<PeripheralConnectionStateChangedEventArgs>? _connectionStateSubscription;

  @override
  bool get isPhysicallyConnected => _connectedPeripheral != null;

  @override
  Stream<List<Device>> get discoveredDevicesStream => _discoveredDevicesController.stream;

  @override
  Future<void> startDiscovery() async {
    try {
      await BleLinkReadiness.ensurePermissions();
      await BleLinkReadiness.ensureManagerPoweredOn(_centralManager);
      await stopDiscovery();
      _foundDevices.clear();
      _discoveredPeripherals.clear();
      _log.d('Starting BLE device scan');

      _scanSubscription = _centralManager.discovered.listen((event) {
        final isOurApp = _isOurApplication(event.advertisement);
        _processDiscoveredDevice(event.peripheral, event.advertisement, isOurApp);
      });

      await _centralManager.startDiscovery(serviceUUIDs: [super.serviceUuid]);
    } on PeerException {
      rethrow;
    } on Object catch (e, stackTrace) {
      _log.e('Failed to start discovery: $e');
      throwPeer(PeerErrorCode.discoveryFailed, cause: e, stackTrace: stackTrace);
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

    try {
      resetIntentionalDisconnect();
      _connectedPeripheral = peripheral;
      _connectionStateSubscription = _centralManager.connectionStateChanged.listen((event) {
        final Peripheral? connected = _connectedPeripheral;
        if (connected == null) return;
        if (event.peripheral.uuid != connected.uuid) return;
        if (event.state == ConnectionState.disconnected) {
          _handleGattDisconnected();
        }
      });

      await _centralManager.connect(peripheral);
      final services = await _centralManager.discoverGATT(peripheral);

      var serviceFound = false;
      for (final service in services) {
        if (service.uuid != super.serviceUuid) continue;
        serviceFound = true;

        for (final characteristic in service.characteristics) {
          if (characteristic.uuid != super.characteristicUuid) continue;

          if (characteristic.properties.contains(GATTCharacteristicProperty.notify)) {
            await _centralManager.setCharacteristicNotifyState(
              peripheral,
              characteristic,
              state: true,
            );
            _dataSubscription = _centralManager.characteristicNotified
                .where((args) => args.characteristic.uuid == super.characteristicUuid)
                .listen((event) => translateIncomingData(event.value));
          }

          if (characteristic.properties.contains(GATTCharacteristicProperty.write) ||
              characteristic.properties.contains(GATTCharacteristicProperty.writeWithoutResponse)) {
            _writeCharacteristic = characteristic;
          }
        }
        break;
      }

      if (!serviceFound) {
        throwPeer(PeerErrorCode.serviceNotFound);
      }

      await _centralManager.requestMTU(peripheral, mtu: 512).catchError((_) => 0);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } on PeerException {
      rethrow;
    } on Object catch (e, stackTrace) {
      await _clearConnectionState();
      throwPeer(PeerErrorCode.connectionFailed, cause: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> sendPhysicalFrame(Uint8List frame) async {
    if (_connectedPeripheral == null || _writeCharacteristic == null) {
      throwPeer(PeerErrorCode.sessionNotConnected);
    }

    try {
      await _centralManager.writeCharacteristic(
        _connectedPeripheral!,
        _writeCharacteristic!,
        value: frame,
        type: GATTCharacteristicWriteType.withoutResponse,
      );
    } on Object catch (e, stackTrace) {
      _log.e('Failed to send data: $e');
      if (_isGattError133(e)) {
        await _resetConnection();
      }
      throwPeer(PeerErrorCode.messageSendFailed, cause: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> disconnect() async {
    beginIntentionalDisconnect();
    await _clearConnectionState();
    resetIntentionalDisconnect();
  }

  @override
  Future<void> onDispose() async {
    await _discoveredDevicesController.close();
    await _scanSubscription?.cancel();
    await _dataSubscription?.cancel();
    await _connectionStateSubscription?.cancel();
    await stopDiscovery();
    beginIntentionalDisconnect();
    await _clearConnectionState();
  }

  void _handleGattDisconnected() {
    if (intentionalDisconnect) return;
    unawaited(_clearConnectionState());
    emitLinkLost();
  }

  Future<void> _clearConnectionState() async {
    await _dataSubscription?.cancel();
    _dataSubscription = null;
    await _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;

    final Peripheral? peripheral = _connectedPeripheral;
    _connectedPeripheral = null;
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

  void _processDiscoveredDevice(Peripheral peripheral, Advertisement advertisement, bool isOurApp) {
    final deviceName = advertisement.name ?? peripheral.uuid.toString();
    final deviceId = peripheral.uuid.toString();
    _discoveredPeripherals[deviceId] = peripheral;
    var cleanName = _getCleanDeviceName(deviceName, super.appName);
    if (_deviceNamePrefix.isNotEmpty) {
      cleanName = cleanName.replaceFirst(_deviceNamePrefix, '');
    }
    final discovered = Device(id: deviceId, name: cleanName, isOurApp: isOurApp);
    if (_foundDevices.any((p) => p.id == discovered.id)) return;
    isOurApp ? _foundDevices.insert(0, discovered) : _foundDevices.add(discovered);
    _discoveredDevicesController.add(List.unmodifiable(_foundDevices));
  }

  String _getCleanDeviceName(String deviceName, String appName) {
    if (!deviceName.contains(appName)) return deviceName;
    var cleanName = deviceName.replaceAll(appName, '').replaceAll('🎮', '').trim();
    return cleanName.startsWith('-') ? cleanName.substring(1).trim() : cleanName;
  }

  bool _isGattError133(Object e) {
    final text = e.toString();
    return text.contains('status: 133') ||
        text.contains('GATT_ERROR') ||
        text.contains('IllegalStateException');
  }

  Future<void> _resetConnection() async {
    beginIntentionalDisconnect();
    await _clearConnectionState();
    resetIntentionalDisconnect();
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}
