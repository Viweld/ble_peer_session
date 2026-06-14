import 'package:meta/meta.dart';

import 'peer_endpoint.dart';

/// Reserved [type] values for the consent handshake between two peers.
abstract final class PeerMessageTypes {
  static const String sessionInvite = 'peer.session.invite';
  static const String sessionAccept = 'peer.session.accept';
  static const String sessionReject = 'peer.session.reject';
  static const String sessionDisconnect = 'peer.session.disconnect';

  static bool isSessionType(String type) => type.startsWith('peer.session.');
}

/// Wire envelope for session handshake and application payloads.
@immutable
final class PeerMessage {
  const PeerMessage({required this.sender, required this.type, this.payload});

  final PeerEndpoint sender;
  final String type;
  final Map<String, dynamic>? payload;
}
