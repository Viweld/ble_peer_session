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
}
