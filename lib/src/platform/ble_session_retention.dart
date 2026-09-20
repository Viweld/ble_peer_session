/// Process-local lease for Android BLE foreground retention.
abstract interface class BleSessionRetention {
  Stream<void> get taskRemoved;

  Future<void> retain();

  Future<void> release();

  Future<void> reconcile();
}

final class NoOpBleSessionRetention implements BleSessionRetention {
  const NoOpBleSessionRetention();

  @override
  Stream<void> get taskRemoved => const Stream<void>.empty();

  @override
  Future<void> retain() async {}

  @override
  Future<void> release() async {}

  @override
  Future<void> reconcile() async {}
}
