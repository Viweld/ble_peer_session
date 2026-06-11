/// Конфигурация BLE P2P-сессии.
final class BlePeerConfig {
  const BlePeerConfig({
    required this.appName,
    required this.serviceUuid,
    required this.characteristicUuid,
    this.deviceNamePrefix = '',
    this.protocolVersion = 1,
    this.frameMaxPayloadBytes = 512,
    this.enableAck = false,
  });

  final String appName;
  final String serviceUuid;
  final String characteristicUuid;
  final String deviceNamePrefix;
  final int protocolVersion;
  final int frameMaxPayloadBytes;
  final bool enableAck;
}
