import 'dart:async';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

import '../../../config/ble_peer_config.dart';
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
      _log.d('Запуск поиска Bluetooth устройств');

      _scanSubscription = _centralManager.discovered.listen((event) {
        final isOurApp = _isOurApplication(event.advertisement);
        _processDiscoveredDevice(event.peripheral, event.advertisement, isOurApp);
      });

      await _centralManager.startDiscovery(serviceUUIDs: [super.serviceUuid]);
    } catch (e) {
      _log.e('Ошибка запуска сканирования: $e');
      throw Exception('Ошибка поиска устройств: $e');
    }
  }

  @override
  Future<void> stopDiscovery() async {
    try {
      await _centralManager.stopDiscovery();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
    } catch (e) {
      _log.e('Ошибка остановки сканирования: $e');
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
      throw Exception('Устройство не найдено в списке обнаруженных');
    }

    try {
      _connectedPeripheral = peripheral;
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
        throw Exception('На устройстве не найден сервис ${super.serviceUuid}');
      }

      await _centralManager.requestMTU(peripheral, mtu: 512).catchError((_) => 0);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      _connectedPeripheral = null;
      _writeCharacteristic = null;
      rethrow;
    }
  }

  @override
  Future<void> sendRawMessage(Uint8List data) async {
    if (_connectedPeripheral == null || _writeCharacteristic == null) {
      throw Exception('Нет активного соединения или характеристики для записи');
    }

    try {
      await _centralManager.writeCharacteristic(
        _connectedPeripheral!,
        _writeCharacteristic!,
        value: data,
        type: GATTCharacteristicWriteType.withoutResponse,
      );
    } on Exception catch (e) {
      _log.e('Ошибка отправки данных: $e');
      if (_isGattError133(e)) {
        await _resetConnection();
      }
      throw Exception('Ошибка отправки данных: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    await _dataSubscription?.cancel();
    _dataSubscription = null;
    if (_connectedPeripheral == null) return;
    try {
      await _centralManager.disconnect(_connectedPeripheral!);
    } catch (e) {
      _log.e('Ошибка отключения: $e');
    } finally {
      _connectedPeripheral = null;
    }
  }

  @override
  Future<void> onDispose() async {
    await _discoveredDevicesController.close();
    await _scanSubscription?.cancel();
    await _dataSubscription?.cancel();
    await stopDiscovery();
    await disconnect();
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

  bool _isGattError133(Exception e) {
    final text = e.toString();
    return text.contains('status: 133') ||
        text.contains('GATT_ERROR') ||
        text.contains('IllegalStateException');
  }

  Future<void> _resetConnection() async {
    await disconnect();
    _writeCharacteristic = null;
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}
