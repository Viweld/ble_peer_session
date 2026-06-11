import '../models/transport_message.dart';

/// Сериализация сообщений транспортного слоя.
abstract interface class Messenger {
  Stream<TransportMessage> get messagesStream;

  Future<void> sendMessage(TransportMessage message);

  Future<void> dispose();
}
