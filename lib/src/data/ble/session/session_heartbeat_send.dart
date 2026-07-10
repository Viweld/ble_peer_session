/// Sends heartbeat transport messages without tearing down the session on transient GATT errors.
Future<void> sendSessionHeartbeat(Future<void> Function() send) async {
  try {
    await send();
  } on Object {
    // Transient GATT write failures are handled by the link layer and watchdog.
  }
}
