import 'ble_peer_uuid_generator.dart';

/// BLE P2P session configuration (service UUIDs and app identifier).
final class BlePeerConfig {
  /// Creates a config with explicit UUIDs.
  ///
  /// Prefer [BlePeerConfig.forApp] for stable UUIDs derived from [appName].
  const BlePeerConfig({
    required this.appName,
    required this.serviceUuid,
    required this.characteristicUuid,
    this.deviceNamePrefix = '',
    this.protocolVersion = 1,
  });

  /// Application identifier shared by host and client (must match on both devices).
  final String appName;

  /// GATT service UUID used for the peer session.
  final String serviceUuid;

  /// GATT characteristic UUID for framed messages.
  final String characteristicUuid;

  /// Optional prefix prepended to the BLE advertised device name.
  final String deviceNamePrefix;

  /// Protocol version embedded in session handshake messages.
  final int protocolVersion;

  /// Stable UUIDs derived from [appName]. Same app name → same UUIDs on every device.
  factory BlePeerConfig.forApp(String appName, {String deviceNamePrefix = ''}) {
    return BlePeerUuidGenerator.configFor(
      appName,
      deviceNamePrefix: deviceNamePrefix,
    );
  }
}
