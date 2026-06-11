import '../models/peer_endpoint.dart';
import 'transport_session.dart';

/// Серверная транспортная сессия.
abstract interface class TransportSessionServer implements TransportSession {
  Future<void> startAdvertising({required PeerEndpoint localPeer});

  Future<void> stopAdvertising();

  Future<void> acceptInvitation();

  Future<void> rejectInvitation();
}
