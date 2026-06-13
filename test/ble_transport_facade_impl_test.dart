import 'dart:async';

import 'package:ble_peer_session/src/data/ble/facade/ble_transport_facade_impl.dart';
import 'package:ble_peer_session/src/domain/models/device.dart';
import 'package:ble_peer_session/src/domain/models/peer_endpoint.dart';
import 'package:ble_peer_session/src/domain/models/peer_identity.dart';
import 'package:ble_peer_session/src/domain/models/transport_message.dart';
import 'package:ble_peer_session/src/domain/transport/models/transport_session_state.dart';
import 'package:ble_peer_session/src/domain/transport/transport_session.dart';
import 'package:ble_peer_session/src/domain/transport/transport_session_client.dart';
import 'package:ble_peer_session/src/domain/transport/transport_session_server.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final PeerEndpoint localPeer = PeerEndpoint(
    identity: const PeerIdentity(id: 'local', displayName: 'Local'),
    device: const Device(id: 'dev-local', name: 'LocalPhone', isOurApp: true),
  );

  group('BleTransportFacadeImpl', () {
    test(
      'startServerTransportSession does not throw when server session is uninitialized',
      () async {
        final FakeTransportSessionClient clientSession = FakeTransportSessionClient();
        final FakeTransportSessionServer serverSession = FakeTransportSessionServer();

        final BleTransportFacadeImpl facade = BleTransportFacadeImpl(
          transportSessionClient: clientSession,
          transportSessionServer: serverSession,
        );

        await expectLater(facade.startServerTransportSession(), completes);
        expect(serverSession.disconnectCallCount, 0);
      },
    );

    test(
      'startClientTransportSession does not throw when server session is uninitialized',
      () async {
        final FakeTransportSessionClient clientSession = FakeTransportSessionClient();
        final FakeTransportSessionServer serverSession = FakeTransportSessionServer();

        final BleTransportFacadeImpl facade = BleTransportFacadeImpl(
          transportSessionClient: clientSession,
          transportSessionServer: serverSession,
        );

        await expectLater(facade.startClientTransportSession(), completes);
        expect(serverSession.disconnectCallCount, 0);
      },
    );

    test('startClientTransportSession resets active server session before role switch', () async {
      final FakeTransportSessionClient clientSession = FakeTransportSessionClient();
      final FakeTransportSessionServer serverSession = FakeTransportSessionServer(
        initialState: TransportSessionDisconnected(localPeer: localPeer),
      );

      final BleTransportFacadeImpl facade = BleTransportFacadeImpl(
        transportSessionClient: clientSession,
        transportSessionServer: serverSession,
      );

      await facade.startClientTransportSession();

      expect(serverSession.disconnectCallCount, 1);
      expect(clientSession.disconnectCallCount, 0);
    });
  });
}

final class FakeTransportSessionClient implements TransportSessionClient {
  FakeTransportSessionClient({TransportSessionState? initialState})
    : _currentConnectionState = initialState;

  TransportSessionState? _currentConnectionState;
  int disconnectCallCount = 0;

  @override
  TransportSessionState? get currentConnectionState => _currentConnectionState;

  @override
  Stream<TransportSessionState> get connectionStateStream => const Stream.empty();

  @override
  Stream<TransportMessage> get messagesStream => const Stream.empty();

  @override
  Stream<List<Device>> get discoveredDevicesStream => const Stream.empty();

  @override
  Future<void> connectToDevice(Device device) async {}

  @override
  Future<void> disconnect() async {
    disconnectCallCount++;
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<void> refreshDiscovery() async {}

  @override
  Future<void> sendMessage(TransportMessage message) async {}

  @override
  Future<void> startDiscovery({required PeerEndpoint localPeer}) async {
    _currentConnectionState = TransportSessionDisconnected(localPeer: localPeer);
  }

  @override
  Future<void> stopDiscovery() async {}
}

final class FakeTransportSessionServer implements TransportSessionServer {
  FakeTransportSessionServer({TransportSessionState? initialState})
    : _currentConnectionState = initialState;

  TransportSessionState? _currentConnectionState;
  int disconnectCallCount = 0;

  @override
  TransportSessionState? get currentConnectionState => _currentConnectionState;

  @override
  Stream<TransportSessionState> get connectionStateStream => const Stream.empty();

  @override
  Stream<TransportMessage> get messagesStream => const Stream.empty();

  @override
  Future<void> acceptInvitation() async {}

  @override
  Future<void> disconnect() async {
    disconnectCallCount++;
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<void> rejectInvitation() async {}

  @override
  Future<void> sendMessage(TransportMessage message) async {}

  @override
  Future<void> startAdvertising({required PeerEndpoint localPeer}) async {
    _currentConnectionState = TransportSessionDisconnected(localPeer: localPeer);
  }

  @override
  Future<void> stopAdvertising() async {}
}
