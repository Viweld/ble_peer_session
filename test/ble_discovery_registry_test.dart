import 'package:ble_peer_session/src/data/ble/discovery/ble_discovery_registry.dart';
import 'package:ble_peer_session/src/domain/models/device.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const Device ours = Device(id: 'a', name: 'Host', isOurApp: true);
  const Device foreign = Device(id: 'b', name: 'Other', isOurApp: false);

  group('BleDiscoveryRegistry', () {
    late List<List<Device>> snapshots;
    late int nowMs;
    late BleDiscoveryRegistry registry;

    setUp(() {
      snapshots = <List<Device>>[];
      nowMs = 0;
      registry = BleDiscoveryRegistry(
        staleAfter: const Duration(seconds: 3),
        sweepInterval: const Duration(milliseconds: 400),
        elapsedMs: () => nowMs,
        autoSweep: false,
        emit: snapshots.add,
      );
    });

    tearDown(() {
      registry.dispose();
    });

    test('scan start emits empty snapshot', () {
      registry.beginGeneration();
      expect(snapshots, <List<Device>>[const <Device>[]]);
    });

    test('valid device appears', () {
      registry.beginGeneration();
      registry.observe(ours);
      expect(snapshots.last, <Device>[ours]);
    });

    test('foreign app is ignored', () {
      registry.beginGeneration();
      registry.observe(foreign);
      expect(snapshots, <List<Device>>[const <Device>[]]);
    });

    test('same id observation refreshes lastSeen and does not duplicate', () {
      registry.beginGeneration();
      registry.observe(ours);
      nowMs = 2000;
      registry.observe(ours);
      nowMs = 4500;
      registry.sweep();
      expect(snapshots.last, <Device>[ours]);
      expect(snapshots.last, hasLength(1));
    });

    test('metadata refresh replaces name', () {
      registry.beginGeneration();
      registry.observe(ours);
      registry.observe(const Device(id: 'a', name: 'Host-2', isOurApp: true));
      expect(snapshots.last.single.name, 'Host-2');
    });

    test('device expires after TTL', () {
      registry.beginGeneration();
      registry.observe(ours);
      nowMs = 3001;
      registry.sweep();
      expect(snapshots.last, isEmpty);
    });

    test('device does not expire while observations continue', () {
      registry.beginGeneration();
      registry.observe(ours);
      nowMs = 2500;
      registry.observe(ours);
      nowMs = 5000;
      registry.sweep();
      expect(snapshots.last, <Device>[ours]);
    });

    test('multiple devices expire independently', () {
      const Device second = Device(id: 'c', name: 'OtherHost', isOurApp: true);
      registry.beginGeneration();
      registry.observe(ours);
      nowMs = 2000;
      registry.observe(second);
      nowMs = 3500;
      registry.sweep();
      expect(snapshots.last.map((Device device) => device.id), <String>['c']);
    });

    test('stop scan clears state', () {
      registry.beginGeneration();
      registry.observe(ours);
      registry.stop();
      expect(snapshots.last, isEmpty);
      registry.observe(ours);
      expect(snapshots.last, isEmpty);
    });

    test('new scan generation starts empty', () {
      registry.beginGeneration();
      registry.observe(ours);
      registry.beginGeneration();
      expect(snapshots.last, isEmpty);
    });

    test('dispose cancels cleanup and suppresses emissions', () {
      registry.beginGeneration();
      final int before = snapshots.length;
      registry.dispose();
      nowMs = 5000;
      registry.sweep();
      registry.observe(ours);
      expect(snapshots.length, before);
    });
  });
}
