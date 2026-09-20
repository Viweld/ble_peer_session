import 'dart:async';

import 'package:ble_peer_session/src/config/ble_android_foreground_config.dart';
import 'package:ble_peer_session/src/domain/exceptions/peer_exception.dart';
import 'package:ble_peer_session/src/platform/ble_android_foreground_bridge.dart';
import 'package:ble_peer_session/src/platform/ble_android_foreground_controller.dart';
import 'package:ble_peer_session/src/platform/ble_session_retention.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const BleAndroidForegroundConfig config = BleAndroidForegroundConfig(
    title: 'Test',
  );

  group('BleAndroidForegroundController', () {
    late _FakeBridge bridge;
    late BleAndroidForegroundController controller;

    setUp(() {
      bridge = _FakeBridge();
      controller = BleAndroidForegroundController(
        config: config,
        bridge: bridge,
      );
    });

    test('retain starts once for duplicate acquire', () async {
      await controller.retain();
      await controller.retain();
      expect(bridge.starts, 1);
      expect(bridge.stops, 0);
    });

    test('release stops once the last lease drops', () async {
      await controller.retain();
      await controller.retain();
      await controller.release();
      expect(bridge.stops, 0);
      await controller.release();
      expect(bridge.stops, 1);
    });

    test('connect failure path releases the lease', () async {
      await controller.retain();
      await controller.release();
      expect(bridge.starts, 1);
      expect(bridge.stops, 1);
    });

    test('cancel and disconnect are idempotent releases', () async {
      await controller.retain();
      await controller.release();
      await controller.release();
      expect(bridge.stops, 1);
    });

    test('reconnect starts a new session', () async {
      await controller.retain();
      await controller.release();
      await controller.retain();
      expect(bridge.starts, 2);
      expect(bridge.stops, 1);
    });

    test(
      'cold reconcile stops a stale service when no lease is held',
      () async {
        await controller.reconcile();
        expect(bridge.stops, 1);
        expect(bridge.starts, 0);
      },
    );

    test('failed start does not keep a lease', () async {
      bridge.startError = PeerException(PeerErrorCode.unexpected);
      await expectLater(controller.retain(), throwsA(isA<PeerException>()));
      await controller.reconcile();
      expect(bridge.stops, 1);
    });
  });

  test('disabled FGS never talks to the native bridge', () async {
    const NoOpBleSessionRetention retention = NoOpBleSessionRetention();
    await retention.retain();
    await retention.release();
    await retention.reconcile();
  });
}

final class _FakeBridge implements BleAndroidForegroundBridge {
  final StreamController<void> _taskRemoved =
      StreamController<void>.broadcast();
  int starts = 0;
  int stops = 0;
  Object? startError;

  @override
  Stream<void> get taskRemoved => _taskRemoved.stream;

  @override
  Future<void> start({
    required String title,
    required String body,
    String? smallIcon,
  }) async {
    final Object? error = startError;
    if (error != null) throw error;
    starts++;
  }

  @override
  Future<void> stop() async {
    stops++;
  }
}
