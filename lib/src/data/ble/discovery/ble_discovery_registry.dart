import 'dart:async';

import '../../../domain/models/device.dart';

typedef ElapsedMilliseconds = int Function();

/// Live nearby-host snapshot with monotonic lastSeen / TTL.
final class BleDiscoveryRegistry {
  BleDiscoveryRegistry({
    required this.staleAfter,
    required this.emit,
    required this.elapsedMs,
    this.sweepInterval = const Duration(milliseconds: 400),
    this.autoSweep = true,
  });

  final Duration staleAfter;
  final Duration sweepInterval;
  final void Function(List<Device> devices) emit;
  final ElapsedMilliseconds elapsedMs;
  final bool autoSweep;

  final Map<String, _TrackedDevice> _devices = <String, _TrackedDevice>{};
  Timer? _sweeper;
  bool _disposed = false;
  bool _active = false;

  void beginGeneration() {
    if (_disposed) return;
    _stopSweeper();
    _devices.clear();
    _active = true;
    emit(const <Device>[]);
    _startSweeper();
  }

  void observe(Device device) {
    if (_disposed || !_active) return;
    if (!device.isOurApp) return;

    final _TrackedDevice? existing = _devices[device.id];
    final int now = elapsedMs();
    if (existing == null) {
      _devices[device.id] = _TrackedDevice(device: device, lastSeenMs: now);
      _emitSnapshot();
      return;
    }

    existing.lastSeenMs = now;
    final bool metadataChanged = existing.device.name != device.name;
    if (metadataChanged) {
      existing.device = device;
      _emitSnapshot();
    }
  }

  void stop() {
    if (_disposed) return;
    _stopSweeper();
    _devices.clear();
    _active = false;
    emit(const <Device>[]);
  }

  void dispose() {
    _disposed = true;
    _stopSweeper();
    _devices.clear();
    _active = false;
  }

  void sweep() {
    if (_disposed || !_active) return;
    final int now = elapsedMs();
    final int staleMs = staleAfter.inMilliseconds;
    final int before = _devices.length;
    _devices.removeWhere(
      (_, _TrackedDevice tracked) => now - tracked.lastSeenMs > staleMs,
    );
    if (_devices.length != before) {
      _emitSnapshot();
    }
  }

  void _emitSnapshot() {
    if (_disposed) return;
    emit(
      List<Device>.unmodifiable(
        _devices.values.map((_TrackedDevice tracked) => tracked.device),
      ),
    );
  }

  void _startSweeper() {
    if (!autoSweep) return;
    _sweeper = Timer.periodic(sweepInterval, (_) => sweep());
  }

  void _stopSweeper() {
    _sweeper?.cancel();
    _sweeper = null;
  }
}

final class _TrackedDevice {
  _TrackedDevice({required this.device, required this.lastSeenMs});

  Device device;
  int lastSeenMs;
}
