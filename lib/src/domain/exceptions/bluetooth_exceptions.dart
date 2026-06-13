/// Bluetooth-адаптер выключен или недоступен.
final class BluetoothDisabledException implements Exception {
  @override
  String toString() => 'BluetoothDisabledException: Bluetooth выключен';
}

/// Устройство не поддерживает BLE peripheral/advertising.
final class BluetoothUnsupportedException implements Exception {
  @override
  String toString() => 'BluetoothUnsupportedException: BLE peripheral не поддерживается';
}

/// Runtime-разрешения Bluetooth не выданы приложению.
final class BluetoothPermissionsDeniedException implements Exception {
  @override
  String toString() => 'BluetoothPermissionsDeniedException: Нет разрешений Bluetooth';
}

/// GATT server / advertiser недоступен (часто из-за permissions или эмулятора).
final class BluetoothPeripheralUnavailableException implements Exception {
  @override
  String toString() => 'BluetoothPeripheralUnavailableException: BLE peripheral недоступен';
}
