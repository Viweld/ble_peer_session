import '../internal/transport_message.dart';
import 'models/transport_session_state.dart';
import 'transport_session.dart';
import 'transport_session_client.dart';
import 'transport_session_server.dart';

/// Internal facade for role switching between client and server sessions.
abstract interface class TransportFacade {
  Stream<TransportMessage> get messagesStream;

  Stream<TransportSessionState> get connectionStateStream;

  TransportSession get transportSession;

  Future<void> sendMessage(TransportMessage message);

  Future<TransportSessionClient> startClientTransportSession();

  Future<TransportSessionServer> startServerTransportSession();

  Future<void> dispose();
}
