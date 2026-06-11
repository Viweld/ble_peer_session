/// Контракт управления состоянием Bluetooth-адаптера.
abstract interface class BluetoothStateService {
  Future<bool> isBluetoothEnabled();

  Future<bool> enableBluetooth();
}
