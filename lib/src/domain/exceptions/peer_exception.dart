/// Classifies recoverable and diagnostic BLE peer session failures.
enum PeerErrorCode {
  bluetoothDisabled,
  bluetoothUnsupported,
  bluetoothUnauthorized,
  permissionsDenied,
  permissionsPermanentlyDenied,
  adapterNotReady,
  peripheralUnavailable,
  advertisingFailed,
  discoveryFailed,
  deviceNotFound,
  connectionFailed,
  connectionTimeout,
  serviceNotFound,
  characteristicNotFound,
  sessionNotConnected,
  remoteRejected,
  remoteDisconnected,
  payloadTooLarge,
  messageEncodeFailed,
  messageDecodeFailed,
  messageSendFailed,
  disposed,
  operationCancelled,
  unexpected,
}

/// Single public error type for the ble_peer_session package.
final class PeerException implements Exception {
  const PeerException(this.code, {this.cause, this.stackTrace});

  final PeerErrorCode code;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final Object? cause = this.cause;
    if (cause == null) {
      return 'PeerException($code)';
    }
    return 'PeerException($code): $cause';
  }
}

Never throwPeer(PeerErrorCode code, {Object? cause, StackTrace? stackTrace}) {
  throw PeerException(code, cause: cause, stackTrace: stackTrace);
}
