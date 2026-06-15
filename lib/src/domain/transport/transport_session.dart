import '../internal/transport_message.dart';
import 'models/transport_session_disconnect_event.dart';
import 'models/transport_session_state.dart';

/// Base contract for an active transport session (internal, not exported).
abstract interface class TransportSession {
  TransportSessionState? get currentConnectionState;

  Stream<TransportSessionState> get connectionStateStream;

  Stream<TransportSessionDisconnectEvent> get disconnectEventStream;

  Stream<TransportMessage> get messagesStream;

  Future<void> sendMessage(TransportMessage message);

  Future<void> disconnect();

  Future<void> dispose();
}
