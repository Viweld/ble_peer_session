import 'dart:async';

import '../config/ble_android_foreground_config.dart';
import 'ble_android_foreground_bridge.dart';
import 'ble_session_retention.dart';

/// Process-wide lease over a single Android BLE foreground service.
final class BleAndroidForegroundController implements BleSessionRetention {
  BleAndroidForegroundController({
    required BleAndroidForegroundConfig config,
    required BleAndroidForegroundBridge bridge,
  }) : _config = config,
       _bridge = bridge;

  final BleAndroidForegroundConfig _config;
  final BleAndroidForegroundBridge _bridge;
  int _leases = 0;
  bool _starting = false;

  @override
  Stream<void> get taskRemoved => _bridge.taskRemoved;

  @override
  Future<void> retain() async {
    _leases++;
    if (_leases != 1) return;
    _starting = true;
    try {
      await _bridge.start(
        title: _config.title,
        body: _config.body,
        smallIcon: _config.smallIcon,
      );
    } on Object {
      _leases--;
      rethrow;
    } finally {
      _starting = false;
    }
  }

  @override
  Future<void> release() async {
    if (_leases == 0) return;
    _leases--;
    if (_leases != 0) return;
    await _bridge.stop();
  }

  @override
  Future<void> reconcile() async {
    if (_leases != 0 || _starting) return;
    await _bridge.stop();
  }
}
