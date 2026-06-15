import 'dart:async';

/// Keeps a connected BLE session alive and detects silent link loss.
final class SessionLivenessMonitor {
  SessionLivenessMonitor({
    required Future<void> Function() onSendPing,
    required void Function() onTimeout,
    this.heartbeatInterval = const Duration(seconds: 5),
    this.heartbeatTimeout = const Duration(seconds: 15),
  }) : _onSendPing = onSendPing,
       _onTimeout = onTimeout;

  final Future<void> Function() _onSendPing;
  final void Function() _onTimeout;
  final Duration heartbeatInterval;
  final Duration heartbeatTimeout;

  Timer? _heartbeatTimer;
  Timer? _watchdogTimer;
  DateTime _lastActivityAt = DateTime.now();
  bool _isRunning = false;
  bool _timeoutReported = false;

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _timeoutReported = false;
    recordActivity();

    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      unawaited(_onSendPing());
    });

    _watchdogTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkTimeout(),
    );
  }

  void stop() {
    _isRunning = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
  }

  void recordActivity() {
    _lastActivityAt = DateTime.now();
  }

  void _checkTimeout() {
    if (!_isRunning || _timeoutReported) return;
    if (DateTime.now().difference(_lastActivityAt) < heartbeatTimeout) return;

    _timeoutReported = true;
    stop();
    _onTimeout();
  }
}
