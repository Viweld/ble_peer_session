import 'logger.dart';

/// No-op logger used when [Peer.create] is called without an explicit [Logger].
final class SilentLogger implements Logger {
  const SilentLogger();

  @override
  void d(String message) {}

  @override
  void e(String message) {}

  @override
  void i(String message) {}

  @override
  void w(String message) {}
}
