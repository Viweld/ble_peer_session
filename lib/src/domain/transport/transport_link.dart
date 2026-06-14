import 'dart:typed_data';

/// Raw byte channel over BLE (internal).
abstract interface class TransportLink {
  Stream<Uint8List> get incomingRawMessageStream;

  Future<void> sendRawMessage(Uint8List data);

  Future<void> disconnect();

  Future<void> dispose();
}
