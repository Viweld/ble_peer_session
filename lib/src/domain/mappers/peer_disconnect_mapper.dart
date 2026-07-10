import '../models/peer_disconnect_info.dart';
import '../transport/models/transport_session_disconnect_event.dart';

abstract final class PeerDisconnectMapper {
  static PeerDisconnectInfo fromTransport(TransportSessionDisconnectEvent event) {
    return PeerDisconnectInfo(reason: event.reason, remotePeer: event.remotePeer);
  }
}
