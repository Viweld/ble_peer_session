import 'package:meta/meta.dart';

import 'peer_endpoint.dart';

/// High-level connection lifecycle exposed to applications.
enum PeerConnectionPhase {
  idle,
  waitingForPeer,
  awaitingUserDecision,
  awaitingRemoteDecision,
  connected,
}

/// Snapshot of the active peer session.
@immutable
final class PeerConnectionInfo {
  const PeerConnectionInfo({required this.phase, required this.localPeer, this.remotePeer});

  final PeerConnectionPhase phase;
  final PeerEndpoint localPeer;
  final PeerEndpoint? remotePeer;
}
