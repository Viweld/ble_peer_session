/// Bluetooth-адаптер выключен или недоступен.
final class BluetoothDisabledException implements Exception {
  @override
  String toString() => 'BluetoothDisabledException: Bluetooth выключен';
}
