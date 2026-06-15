import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:ble_peer_session/src/data/ble/session/session_liveness_monitor.dart';

void main() {
  test('fires timeout when no activity within heartbeat window', () async {
    var timeoutCount = 0;

    final SessionLivenessMonitor monitor = SessionLivenessMonitor(
      heartbeatInterval: const Duration(milliseconds: 100),
      heartbeatTimeout: const Duration(milliseconds: 250),
      onSendPing: () async {},
      onTimeout: () => timeoutCount++,
    );

    monitor.start();
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    monitor.stop();

    expect(timeoutCount, 1);
  });

  test('incoming activity resets watchdog', () async {
    var timeoutCount = 0;

    final SessionLivenessMonitor monitor = SessionLivenessMonitor(
      heartbeatInterval: const Duration(milliseconds: 100),
      heartbeatTimeout: const Duration(milliseconds: 300),
      onSendPing: () async {},
      onTimeout: () => timeoutCount++,
    );

    monitor.start();

    for (int i = 0; i < 4; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      monitor.recordActivity();
    }

    monitor.stop();
    expect(timeoutCount, 0);
  });
}
