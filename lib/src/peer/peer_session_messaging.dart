import '../domain/exceptions/peer_exception.dart';
import '../domain/models/peer_endpoint.dart';
import '../domain/models/peer_message.dart';

/// High-level text/JSON helpers shared by [PeerHost] and [PeerClient].
abstract interface class PeerSessionMessaging {
  PeerEndpoint? get localEndpoint;

  Stream<PeerMessage> get messagesStream;

  Future<void> send(PeerMessage message);
}

extension PeerSessionMessagingX on PeerSessionMessaging {
  /// Incoming plain-text chat messages (`PeerMessageTypes.appText`).
  Stream<String> get textMessages => messagesStream
      .where((PeerMessage message) => message.type == PeerMessageTypes.appText)
      .map((PeerMessage message) => message.payload?['text'] as String? ?? '');

  /// Incoming application JSON payloads (excludes session handshake and text).
  Stream<Map<String, dynamic>> get jsonMessages => messagesStream
      .where(
        (PeerMessage message) =>
            !PeerMessageTypes.isSessionType(message.type) &&
            message.type != PeerMessageTypes.appText,
      )
      .map((PeerMessage message) => message.payload ?? const <String, dynamic>{});

  /// Sends a plain-text message using the stored local endpoint.
  Future<void> sendText(String text) {
    final PeerEndpoint? endpoint = localEndpoint;
    if (endpoint == null) {
      throwPeer(PeerErrorCode.sessionNotConnected);
    }
    return send(PeerMessage.text(sender: endpoint, text: text));
  }

  /// Sends a typed application payload using the stored local endpoint.
  Future<void> sendJson(String type, [Map<String, dynamic>? payload]) {
    final PeerEndpoint? endpoint = localEndpoint;
    if (endpoint == null) {
      throwPeer(PeerErrorCode.sessionNotConnected);
    }
    return send(PeerMessage.app(sender: endpoint, type: type, payload: payload));
  }
}
