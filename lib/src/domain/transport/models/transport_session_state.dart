import '../../models/peer_endpoint.dart';

/// Базовый тип состояний транспортной сессии.
sealed class TransportSessionState {
  const TransportSessionState({required this.localPeer});

  final PeerEndpoint localPeer;
}

/// Сессия неактивна или завершена.
final class TransportSessionDisconnected extends TransportSessionState {
  const TransportSessionDisconnected({required super.localPeer});
}

/// Получено приглашение — ожидается решение пользователя.
final class TransportSessionAwaitingUserDecision extends TransportSessionState {
  const TransportSessionAwaitingUserDecision({
    required super.localPeer,
    required this.remotePeer,
  });

  final PeerEndpoint remotePeer;
}

/// Отправлено приглашение — ожидается ответ удалённой стороны.
final class TransportSessionAwaitingRemoteDecision extends TransportSessionState {
  const TransportSessionAwaitingRemoteDecision({required super.localPeer});
}

/// Сессия установлена — соединение активно.
final class TransportSessionConnected extends TransportSessionState {
  const TransportSessionConnected({
    required super.localPeer,
    required this.remotePeer,
  });

  final PeerEndpoint remotePeer;
}
