import '../../models/peer_endpoint.dart';

/// Base type for internal transport session FSM states.
sealed class TransportSessionState {
  const TransportSessionState({required this.localPeer});

  final PeerEndpoint localPeer;
}

/// Session is idle or finished; host is advertising or client is discovering.
final class TransportSessionDisconnected extends TransportSessionState {
  const TransportSessionDisconnected({required super.localPeer});
}

/// Host received an invite and waits for the user to accept or reject.
final class TransportSessionAwaitingUserDecision extends TransportSessionState {
  const TransportSessionAwaitingUserDecision({required super.localPeer, required this.remotePeer});

  final PeerEndpoint remotePeer;
}

/// Client sent an invite and waits for the host response.
final class TransportSessionAwaitingRemoteDecision extends TransportSessionState {
  const TransportSessionAwaitingRemoteDecision({required super.localPeer});
}

/// Session is established and application messages can flow.
final class TransportSessionConnected extends TransportSessionState {
  const TransportSessionConnected({required super.localPeer, required this.remotePeer});

  final PeerEndpoint remotePeer;
}
