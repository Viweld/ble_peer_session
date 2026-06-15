import 'ble_peer_uuid_generator.dart';

/// BLE P2P session configuration (service UUIDs and app identifier).
final class BlePeerConfig {
  const BlePeerConfig({
    required this.appName,
    required this.serviceUuid,
    required this.characteristicUuid,
    this.deviceNamePrefix = '',
    this.protocolVersion = 1,
  });

  final String appName;
  final String serviceUuid;
  final String characteristicUuid;
  final String deviceNamePrefix;
  final int protocolVersion;

  /// Stable UUIDs derived from [appName]. Same app name → same UUIDs on every device.
  factory BlePeerConfig.forApp(String appName, {String deviceNamePrefix = ''}) {
    return BlePeerUuidGenerator.configFor(appName, deviceNamePrefix: deviceNamePrefix);
  }
}
