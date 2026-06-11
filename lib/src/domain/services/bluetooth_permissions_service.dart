/// Контракт проверки Bluetooth-разрешений.
abstract interface class BluetoothPermissionsService {
  Future<bool> checkPermissions();

  Future<bool> openAppSettings();
}
