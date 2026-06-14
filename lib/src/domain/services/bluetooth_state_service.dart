/// Internal Bluetooth adapter helper (not exported).
abstract interface class BluetoothStateService {
  Future<bool> isBluetoothEnabled();

  Future<bool> enableBluetooth();
}
