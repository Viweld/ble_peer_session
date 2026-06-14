import 'package:meta/meta.dart';

import '../models/peer_endpoint.dart';

/// Internal transport envelope base type (not part of the public API).
@immutable
sealed class TransportMessage {
  const TransportMessage({required this.peerEndpoint});

  final PeerEndpoint peerEndpoint;
}

@immutable
final class InvitationMessage extends TransportMessage {
  const InvitationMessage({required super.peerEndpoint});
}

@immutable
final class AcceptanceMessage extends TransportMessage {
  const AcceptanceMessage({required super.peerEndpoint});
}

@immutable
final class RejectionMessage extends TransportMessage {
  const RejectionMessage({required super.peerEndpoint});
}

@immutable
final class DisconnectionMessage extends TransportMessage {
  const DisconnectionMessage({required super.peerEndpoint});
}

/// Application payload on the wire before public [PeerMessage] mapping.
@immutable
final class AppTransportMessage extends TransportMessage {
  const AppTransportMessage({required super.peerEndpoint, required this.type, this.payload});

  final String type;
  final Map<String, dynamic>? payload;
}
