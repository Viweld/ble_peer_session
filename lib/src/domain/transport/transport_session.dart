import '../models/transport_message.dart';
import 'models/transport_session_state.dart';

/// Базовый контракт транспортной сессии.
abstract interface class TransportSession {
  TransportSessionState? get currentConnectionState;

  Stream<TransportSessionState> get connectionStateStream;

  Stream<TransportMessage> get messagesStream;

  Future<void> sendMessage(TransportMessage message);

  Future<void> disconnect();

  Future<void> dispose();
}
