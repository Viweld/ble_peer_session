import 'package:meta/meta.dart';

import 'peer_endpoint.dart';

/// Базовое сообщение транспортного слоя.
@immutable
sealed class TransportMessage {
  const TransportMessage({required this.peerEndpoint});

  final PeerEndpoint peerEndpoint;
}

/// Приглашение к подключению.
@immutable
final class InvitationMessage extends TransportMessage {
  const InvitationMessage({required super.peerEndpoint});
}

/// Согласие на подключение.
@immutable
final class AcceptanceMessage extends TransportMessage {
  const AcceptanceMessage({required super.peerEndpoint});
}

/// Отказ от подключения.
@immutable
final class RejectionMessage extends TransportMessage {
  const RejectionMessage({required super.peerEndpoint});
}

/// Одностороннее прекращение соединения.
@immutable
final class DisconnectionMessage extends TransportMessage {
  const DisconnectionMessage({required super.peerEndpoint});
}

/// Прикладное сообщение с произвольным типом и payload.
@immutable
final class PeerMessage extends TransportMessage {
  const PeerMessage({
    required super.peerEndpoint,
    required this.type,
    this.payload,
  });

  final String type;
  final Map<String, dynamic>? payload;
}
