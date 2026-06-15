import 'dart:typed_data';

/// Raw byte channel over BLE (internal).
abstract interface class TransportLink {
  Stream<Uint8List> get incomingRawMessageStream;

  /// Fires when the GATT link drops without an intentional local [disconnect].
  Stream<void> get linkLostStream;

  bool get isPhysicallyConnected;

  Future<void> sendRawMessage(Uint8List data);

  Future<void> disconnect();

  Future<void> dispose();
}
