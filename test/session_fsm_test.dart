import 'package:ble_peer_session/ble_peer_session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ble_peer_session/src/domain/mappers/peer_connection_mapper.dart';
import 'package:ble_peer_session/src/domain/transport/models/transport_session_state.dart';

void main() {
  final localPeer = PeerEndpoint(
    identity: PeerIdentity(id: 'local', displayName: 'Local'),
    device: Device(id: 'dev-local', name: 'LocalPhone', isOurApp: true),
  );

  final remotePeer = PeerEndpoint(
    identity: PeerIdentity(id: 'remote', displayName: 'Remote'),
    device: Device(id: 'dev-remote', name: 'RemotePhone', isOurApp: true),
  );

  test('maps disconnected internal state to waitingForPeer', () {
    final info = PeerConnectionMapper.fromSessionState(
      TransportSessionDisconnected(localPeer: localPeer),
    );

    expect(info?.phase, PeerConnectionPhase.waitingForPeer);
  });

  test('maps connected internal state to connected phase', () {
    final info = PeerConnectionMapper.fromSessionState(
      TransportSessionConnected(localPeer: localPeer, remotePeer: remotePeer),
    );

    expect(info?.phase, PeerConnectionPhase.connected);
    expect(info?.remotePeer?.identity.displayName, 'Remote');
  });

  test('maps awaiting user decision to public phase', () {
    final info = PeerConnectionMapper.fromSessionState(
      TransportSessionAwaitingUserDecision(
        localPeer: localPeer,
        remotePeer: remotePeer,
      ),
    );

    expect(info?.phase, PeerConnectionPhase.awaitingUserDecision);
  });
}
