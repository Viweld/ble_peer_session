/// Classifies GATT central write failures and retry policy for transient errors.
abstract final class BleGattWritePolicy {
  static const int maxAttempts = 3;
  static const Duration retryDelay = Duration(milliseconds: 75);

  static bool isTransientGattWriteError(Object error) {
    final String text = error.toString();
    return text.contains('IllegalStateException') ||
        text.contains('status: 133') ||
        text.contains('GATT_ERROR');
  }

  static bool isGattLinkLostError(Object error) {
    final String text = error.toString();
    return text.contains('status: 133') || text.contains('GATT_ERROR');
  }

  static bool shouldRetryWrite({required int attempt, required Object error}) {
    return attempt < maxAttempts && isTransientGattWriteError(error);
  }
}
