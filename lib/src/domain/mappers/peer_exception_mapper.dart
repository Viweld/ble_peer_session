import '../exceptions/peer_exception.dart';

/// Maps low-level platform errors to [PeerException].
abstract final class PeerExceptionMapper {
  static PeerException from(Object error, [StackTrace? stackTrace]) {
    if (error is PeerException) {
      return error;
    }

    if (error is FormatException) {
      return PeerException(
        PeerErrorCode.messageDecodeFailed,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    final String message = error.toString();

    if (message.contains('service not found') ||
        message.contains('serviceUuid')) {
      return PeerException(
        PeerErrorCode.serviceNotFound,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (message.contains('not found')) {
      return PeerException(
        PeerErrorCode.deviceNotFound,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (message.contains('no active connection') ||
        message.contains('sessionNotConnected')) {
      return PeerException(
        PeerErrorCode.sessionNotConnected,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (message.contains('status: 133') ||
        message.contains('GATT_ERROR') ||
        message.contains('IllegalStateException')) {
      return PeerException(
        PeerErrorCode.connectionFailed,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return PeerException(
      PeerErrorCode.unexpected,
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
