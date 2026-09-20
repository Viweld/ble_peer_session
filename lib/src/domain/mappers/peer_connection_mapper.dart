import '../models/peer_connection_phase.dart';
import '../transport/models/transport_session_state.dart';

/// Maps internal FSM states to the public connection model.
abstract final class PeerConnectionMapper {
  static PeerConnectionInfo? fromSessionState(TransportSessionState? state) {
    if (state == null) {
      return null;
    }

    return switch (state) {
      TransportSessionDisconnected(:final localPeer) => PeerConnectionInfo(
        phase: PeerConnectionPhase.waitingForPeer,
        localPeer: localPeer,
      ),
      TransportSessionAwaitingUserDecision(
        :final localPeer,
        :final remotePeer,
      ) =>
        PeerConnectionInfo(
          phase: PeerConnectionPhase.awaitingUserDecision,
          localPeer: localPeer,
          remotePeer: remotePeer,
        ),
      TransportSessionAwaitingRemoteDecision(:final localPeer) =>
        PeerConnectionInfo(
          phase: PeerConnectionPhase.awaitingRemoteDecision,
          localPeer: localPeer,
        ),
      TransportSessionConnected(:final localPeer, :final remotePeer) =>
        PeerConnectionInfo(
          phase: PeerConnectionPhase.connected,
          localPeer: localPeer,
          remotePeer: remotePeer,
        ),
    };
  }
}
