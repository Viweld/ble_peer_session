import 'dart:async';
import 'dart:typed_data';

import 'package:ble_peer_session/src/data/ble/session/ble_session_client_impl.dart';
import 'package:ble_peer_session/src/domain/exceptions/peer_exception.dart';
import 'package:ble_peer_session/src/domain/internal/transport_message.dart';
import 'package:ble_peer_session/src/domain/models/device.dart';
import 'package:ble_peer_session/src/domain/models/peer_endpoint.dart';
import 'package:ble_peer_session/src/domain/models/peer_identity.dart';
import 'package:ble_peer_session/src/domain/transport/messenger.dart';
import 'package:ble_peer_session/src/domain/transport/transport_link_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const Device host = Device(id: 'host', name: 'Host', isOurApp: true);
  const PeerEndpoint local = PeerEndpoint(
    identity: PeerIdentity(id: 'me', displayName: 'Me'),
    device: Device(id: 'local', name: 'Local', isOurApp: true),
  );

  late _FakeLink link;
  late _FakeMessenger messenger;
  late BleSessionClientImpl session;

  setUp(() async {
    link = _FakeLink();
    messenger = _FakeMessenger();
    session = BleSessionClientImpl(link: link, messenger: messenger);
    await session.startDiscovery(localPeer: local);
  });

  tearDown(() async {
    await session.dispose();
    await link.dispose();
    await messenger.dispose();
  });

  test('cancel before connect completion throws operationCancelled', () async {
    final Future<void> connect = session.connectToDevice(host);
    await Future<void>.delayed(Duration.zero);
    final Future<void> expected = expectLater(
      connect,
      throwsA(
        isA<PeerException>().having(
          (PeerException error) => error.code,
          'code',
          PeerErrorCode.operationCancelled,
        ),
      ),
    );
    await session.cancelPendingConnection();
    await expected;
    expect(messenger.sent, isEmpty);
  });

  test(
    'cancel releases the in-flight connect so a second connect can start',
    () async {
      final Future<void> first = session.connectToDevice(host);
      await Future<void>.delayed(Duration.zero);
      final Future<void> expected = expectLater(
        first,
        throwsA(isA<PeerException>()),
      );
      await session.cancelPendingConnection();
      await expected;

      final Future<void> second = session.connectToDevice(host);
      await Future<void>.delayed(Duration.zero);
      expect(link.connectCalls, 2);
      link.completeConnect();
      await second;
      expect(messenger.sent, hasLength(1));
    },
  );

  test(
    'late connect completion after cancel is ignored by generation',
    () async {
      final Future<void> connect = session.connectToDevice(host);
      await Future<void>.delayed(Duration.zero);
      final Future<void> expected = expectLater(
        connect,
        throwsA(isA<PeerException>()),
      );
      await session.cancelPendingConnection();
      link.completeConnect();
      await expected;
      expect(messenger.sent, isEmpty);
    },
  );

  test('cancel is idempotent', () async {
    await session.cancelPendingConnection();
    await session.cancelPendingConnection();
    expect(link.cancelCalls, 2);
  });

  test('disconnect after cancel is safe', () async {
    final Future<void> connect = session.connectToDevice(host);
    await Future<void>.delayed(Duration.zero);
    final Future<void> expected = expectLater(
      connect,
      throwsA(isA<PeerException>()),
    );
    await session.cancelPendingConnection();
    await expected;
    await expectLater(session.disconnect(), completes);
  });

  test('dispose during connect is safe', () async {
    final Future<void> connect = session.connectToDevice(host);
    await Future<void>.delayed(Duration.zero);
    final Future<void> expected = expectLater(connect, throwsA(anything));
    await session.dispose();
    await expected;
  });
}

final class _FakeLink implements TransportLinkClient {
  final StreamController<List<Device>> _discovered =
      StreamController<List<Device>>.broadcast();
  final StreamController<Uint8List> _incoming =
      StreamController<Uint8List>.broadcast();
  final StreamController<void> _linkLost = StreamController<void>.broadcast();
  Completer<void>? inFlight;
  int connectCalls = 0;
  int cancelCalls = 0;
  int disconnectCalls = 0;

  @override
  Stream<List<Device>> get discoveredDevicesStream => _discovered.stream;

  @override
  Stream<Uint8List> get incomingRawMessageStream => _incoming.stream;

  @override
  Stream<void> get linkLostStream => _linkLost.stream;

  @override
  bool get isPhysicallyConnected => false;

  @override
  Future<void> startDiscovery() async {}

  @override
  Future<void> stopDiscovery() async {}

  @override
  Future<void> refreshDiscovery() async {}

  @override
  Future<void> connectToDevice(Device device) {
    connectCalls++;
    inFlight = Completer<void>();
    return inFlight!.future;
  }

  @override
  Future<void> cancelPendingConnection() async {
    cancelCalls++;
    final Completer<void>? pending = inFlight;
    if (pending == null || pending.isCompleted) return;
    pending.completeError(
      const PeerException(PeerErrorCode.operationCancelled),
    );
  }

  void completeConnect() {
    final Completer<void>? pending = inFlight;
    if (pending == null || pending.isCompleted) return;
    pending.complete();
  }

  @override
  Future<void> sendRawMessage(Uint8List data) async {}

  @override
  Future<void> disconnect() async => disconnectCalls++;

  @override
  Future<void> dispose() async {
    final Completer<void>? pending = inFlight;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(const PeerException(PeerErrorCode.disposed));
    }
    await _discovered.close();
    await _incoming.close();
    await _linkLost.close();
  }
}

final class _FakeMessenger implements Messenger {
  final StreamController<TransportMessage> _messages =
      StreamController<TransportMessage>.broadcast();
  final List<TransportMessage> sent = <TransportMessage>[];

  @override
  Stream<TransportMessage> get messagesStream => _messages.stream;

  @override
  Future<void> sendMessage(TransportMessage message) async {
    sent.add(message);
  }

  @override
  Future<void> dispose() => _messages.close();
}
