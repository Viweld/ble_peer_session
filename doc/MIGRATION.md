# Migration guide: 0.1.x → 0.2.0

Version 0.2.0 is a **breaking** release that simplifies the public API.

See also: [main README](../README.md) · [0.2 → 0.3 guide](MIGRATION_0.3.md) · [doc index](README.md)

---

## Summary

| 0.1.x | 0.2.0 |
|-------|-------|
| `BlePeerSessionModule.create()` | `Peer.create()` |
| `TransportFacade` | `Peer` + `PeerHost` / `PeerClient` |
| `InvitationMessage`, `AcceptanceMessage`, … | `PeerMessage` with `PeerMessageTypes.*` |
| `TransportSessionState` | `PeerConnectionInfo` + `PeerConnectionPhase` |
| `BluetoothDisabledException`, … | `PeerException` + `PeerErrorCode` |
| `BluetoothStateService.enableBluetooth()` | Not used by package; observe `PeerAdapterStatus` |

> **On 0.3+:** use [MIGRATION_0.3.md](MIGRATION_0.3.md) for `Peer.create(appName:)`, `peer.host()` / `peer.client()`, and `invite()`.

---

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

---

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
host.messagesStream.listen((message) {
  switch (message.type) {
    case PeerMessageTypes.sessionInvite:
      await host.accept();
    case 'game.move':
      // application payload in message.payload
  }
});
```

---

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
host.connectionStream.listen((info) {
  if (info?.phase == PeerConnectionPhase.connected) {
    final remote = info!.remotePeer;
  }
});
```

---

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

Full code list: [ERROR_CODES.md](ERROR_CODES.md).

---

## Removed exports

These types are internal in 0.2.0 and must not be imported from app code:

- `TransportFacade`, `TransportSession`, `TransportSessionClient`, `TransportSessionServer`
- `TransportSessionState`, `TransportMessage` hierarchy
- `BluetoothStateService`, `BlePeerSessionModule`
- `bluetooth_exceptions.dart`

---

## Android permissions

Unchanged: request `BLUETOOTH_SCAN`, `CONNECT`, and `ADVERTISE` before host/client operations. See [Platform setup](../README.md#5-platform-setup).
