import '../internal/transport_message.dart';

/// Sends and receives decoded [TransportMessage] instances over the BLE link.
abstract interface class Messenger {
  Stream<TransportMessage> get messagesStream;

  Future<void> sendMessage(TransportMessage message);

  Future<void> dispose();
}
