import '../../models/peer_disconnect_reason.dart';
import '../../models/peer_endpoint.dart';

/// Internal disconnect fact emitted by the transport session FSM.
final class TransportSessionDisconnectEvent {
  const TransportSessionDisconnectEvent({
    required this.reason,
    required this.localPeer,
    this.remotePeer,
  });

  final PeerDisconnectReason reason;
  final PeerEndpoint localPeer;
  final PeerEndpoint? remotePeer;
}
