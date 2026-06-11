/// Контракт логирования для BLE-транспорта.
abstract interface class Logger {
  void d(String message);
  void w(String message);
  void e(String message);
}
