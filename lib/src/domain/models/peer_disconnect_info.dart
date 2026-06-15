import 'package:meta/meta.dart';

import 'peer_disconnect_reason.dart';
import 'peer_endpoint.dart';

/// Emitted when an established session ends for any reason.
@immutable
final class PeerDisconnectInfo {
  const PeerDisconnectInfo({required this.reason, this.remotePeer});

  final PeerDisconnectReason reason;
  final PeerEndpoint? remotePeer;
}
