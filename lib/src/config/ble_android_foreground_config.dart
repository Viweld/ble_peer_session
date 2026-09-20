/// Host branding for the optional Android BLE foreground service.
final class BleAndroidForegroundConfig {
  /// Creates Android foreground branding.
  ///
  /// [smallIcon] is a host resource name such as `@drawable/ic_stat_app`.
  /// `null` uses the package generic status-bar icon.
  const BleAndroidForegroundConfig({
    required this.title,
    this.body = 'Bluetooth peer session is active',
    this.smallIcon,
  });

  /// Notification title (typically the host app name).
  final String title;

  /// Notification body.
  final String body;

  /// Optional Android resource (`@drawable/…` or `@mipmap/…`).
  final String? smallIcon;
}
