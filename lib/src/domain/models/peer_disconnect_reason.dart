/// Why an established BLE peer session ended.
enum PeerDisconnectReason {
  /// Local peer called [PeerHost.disconnect] / [PeerClient.disconnect].
  userDisconnect,

  /// Remote peer sent a graceful session termination message.
  peerDisconnect,

  /// GATT link dropped (out of range, Bluetooth off, OS killed peer, etc.).
  linkLost,

  /// No inbound activity within the heartbeat watchdog window.
  timeout,
}
