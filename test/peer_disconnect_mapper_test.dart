import 'package:ble_peer_session/ble_peer_session.dart';
import 'package:ble_peer_session/src/domain/mappers/peer_disconnect_mapper.dart';
import 'package:ble_peer_session/src/domain/transport/models/transport_session_disconnect_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PeerDisconnectMapper maps transport disconnect event', () {
    final PeerEndpoint localPeer = PeerEndpoint(
      identity: const PeerIdentity(id: 'local', displayName: 'Local'),
      device: const Device(id: 'dev-local', name: 'LocalPhone', isOurApp: true),
    );
    final PeerEndpoint remotePeer = PeerEndpoint(
      identity: const PeerIdentity(id: 'remote', displayName: 'Remote'),
      device: const Device(
        id: 'dev-remote',
        name: 'RemotePhone',
        isOurApp: true,
      ),
    );

    final PeerDisconnectInfo info = PeerDisconnectMapper.fromTransport(
      TransportSessionDisconnectEvent(
        reason: PeerDisconnectReason.linkLost,
        localPeer: localPeer,
        remotePeer: remotePeer,
      ),
    );

    expect(info.reason, PeerDisconnectReason.linkLost);
    expect(info.remotePeer?.identity.displayName, 'Remote');
  });
}
