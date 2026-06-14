/// Bluetooth runtime permission checks (Android 12+).
abstract interface class BluetoothPermissionsService {
  Future<bool> checkPermissions();

  Future<bool> openAppSettings();
}
