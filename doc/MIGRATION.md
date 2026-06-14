# Migration guide: 0.1.x → 0.2.0

Version 0.2.0 is a **breaking** release that simplifies the public API.

## Summary

| 0.1.x | 0.2.0 |
|-------|-------|
| `BlePeerSessionModule.create()` | `Peer.create()` |
| `TransportFacade` | `Peer` + `PeerHost` / `PeerClient` |
| `InvitationMessage`, `AcceptanceMessage`, … | `PeerMessage` with `PeerMessageTypes.*` |
| `TransportSessionState` | `PeerConnectionInfo` + `PeerConnectionPhase` |
| `BluetoothDisabledException`, … | `PeerException` + `PeerErrorCode` |
| `BluetoothStateService.enableBluetooth()` | Not used by package; observe `PeerAdapterStatus` |

## Entry point

**Before:**

```dart
final module = BlePeerSessionModule.create(config: config, logger: logger);
final facade = module.transportFacade;
await facade.startServerTransportSession();
```

**After:**

```dart
final peer = Peer.create(config: config, logger: logger);
final host = await peer.createHost();
await host.start(localPeer: localPeer);
```

## Messages

**Before:**

```dart
facade.messagesStream.listen((message) {
  switch (message) {
    case InvitationMessage(:final peerEndpoint):
      // ...
    case PeerMessage(:final type, :final payload):
      // ...
  }
});
```

**After:**

```dart
peer.messagesStream.listen((message) {
  switch (message.type) {
    case PeerMessageTypes.sessionInvite:
      // message.sender is remote peer
    case 'game.move':
      // application payload in message.payload
  }
});
```

## Connection state

**Before:**

```dart
facade.connectionStateStream.listen((state) {
  switch (state) {
    case TransportSessionConnected(:final remotePeer):
      // ...
  }
});
```

**After:**

```dart
peer.connectionStream.listen((info) {
  if (info?.phase == PeerConnectionPhase.connected) {
    final remote = info!.remotePeer;
  }
});
```

## Errors

**Before:**

```dart
} on BluetoothDisabledException {
```

**After:**

```dart
} on PeerException catch (e) {
  if (e.code == PeerErrorCode.bluetoothDisabled) {
```

## Removed exports

These types are internal in 0.2.0 and must not be imported from app code:

- `TransportFacade`, `TransportSession`, `TransportSessionClient`, `TransportSessionServer`
- `TransportSessionState`, `TransportMessage` hierarchy
- `BluetoothStateService`, `BlePeerSessionModule`
- `bluetooth_exceptions.dart`

## Android permissions

Behavior unchanged: request `BLUETOOTH_SCAN`, `CONNECT`, and `ADVERTISE` before host/client operations. Use `peer.permissions.checkPermissions()`.
