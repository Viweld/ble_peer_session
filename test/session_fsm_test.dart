import 'package:ble_peer_session/ble_peer_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final localPeer = PeerEndpoint(
    identity: PeerIdentity(id: 'local', displayName: 'Local'),
    device: Device(id: 'dev-local', name: 'LocalPhone', isOurApp: true),
  );

  final remotePeer = PeerEndpoint(
    identity: PeerIdentity(id: 'remote', displayName: 'Remote'),
    device: Device(id: 'dev-remote', name: 'RemotePhone', isOurApp: true),
  );

  test('disconnected -> awaiting remote -> connected', () {
    TransportSessionState state = TransportSessionDisconnected(
      localPeer: localPeer,
    );
    expect(state, isA<TransportSessionDisconnected>());

    state = TransportSessionAwaitingRemoteDecision(localPeer: localPeer);
    expect(state, isA<TransportSessionAwaitingRemoteDecision>());

    state = TransportSessionConnected(
      localPeer: localPeer,
      remotePeer: remotePeer,
    );
    expect(state, isA<TransportSessionConnected>());
  });

  test('disconnected -> awaiting user decision -> connected', () {
    final state = TransportSessionAwaitingUserDecision(
      localPeer: localPeer,
      remotePeer: remotePeer,
    );
    expect(state.remotePeer.identity.displayName, 'Remote');
  });
}
