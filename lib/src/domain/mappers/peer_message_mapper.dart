import '../internal/transport_message.dart';
import '../models/peer_message.dart';

/// Maps between public [PeerMessage] and internal [TransportMessage].
abstract final class PeerMessageMapper {
  static PeerMessage fromTransport(TransportMessage message) {
    return switch (message) {
      InvitationMessage(:final peerEndpoint) => PeerMessage(
        sender: peerEndpoint,
        type: PeerMessageTypes.sessionInvite,
      ),
      AcceptanceMessage(:final peerEndpoint) => PeerMessage(
        sender: peerEndpoint,
        type: PeerMessageTypes.sessionAccept,
      ),
      RejectionMessage(:final peerEndpoint) => PeerMessage(
        sender: peerEndpoint,
        type: PeerMessageTypes.sessionReject,
      ),
      DisconnectionMessage(:final peerEndpoint) => PeerMessage(
        sender: peerEndpoint,
        type: PeerMessageTypes.sessionDisconnect,
      ),
      AppTransportMessage(:final peerEndpoint, :final type, :final payload) => PeerMessage(
        sender: peerEndpoint,
        type: type,
        payload: payload,
      ),
    };
  }

  static TransportMessage toTransport(PeerMessage message) {
    return switch (message.type) {
      PeerMessageTypes.sessionInvite => InvitationMessage(peerEndpoint: message.sender),
      PeerMessageTypes.sessionAccept => AcceptanceMessage(peerEndpoint: message.sender),
      PeerMessageTypes.sessionReject => RejectionMessage(peerEndpoint: message.sender),
      PeerMessageTypes.sessionDisconnect => DisconnectionMessage(peerEndpoint: message.sender),
      _ => AppTransportMessage(
        peerEndpoint: message.sender,
        type: message.type,
        payload: message.payload,
      ),
    };
  }
}
