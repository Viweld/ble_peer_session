import 'ble_android_foreground_config.dart';
import 'ble_peer_uuid_generator.dart';

export 'ble_android_foreground_config.dart';

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
    this.discoveryStaleAfter = const Duration(seconds: 3),
    this.discoverySweepInterval = const Duration(milliseconds: 400),
    this.androidForeground,
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

  /// A discovered host disappears from snapshots after this monotonic idle period.
  final Duration discoveryStaleAfter;

  /// How often the discovery registry evicts stale hosts.
  final Duration discoverySweepInterval;

  /// Optional Android foreground-service branding. `null` disables FGS.
  final BleAndroidForegroundConfig? androidForeground;

  /// Stable UUIDs derived from [appName]. Same app name → same UUIDs on every device.
  factory BlePeerConfig.forApp(
    String appName, {
    String deviceNamePrefix = '',
    Duration discoveryStaleAfter = const Duration(seconds: 3),
    Duration discoverySweepInterval = const Duration(milliseconds: 400),
    BleAndroidForegroundConfig? androidForeground,
  }) {
    return BlePeerUuidGenerator.configFor(
      appName,
      deviceNamePrefix: deviceNamePrefix,
      discoveryStaleAfter: discoveryStaleAfter,
      discoverySweepInterval: discoverySweepInterval,
      androidForeground: androidForeground,
    );
  }
}
