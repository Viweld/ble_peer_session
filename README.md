# ble_peer_session

> Offline 1:1 peer sessions over BLE (host / client model)

**Scope:** 1:1 only (one host + one client). No Wi‑Fi or internet required.

![Host–client connection flow: discover → invite → accept → connected (sendText / sendJson)](https://raw.githubusercontent.com/Viweld/ble_peer_session/main/doc/assets/connection-flow.jpg)

### Use cases

- Local multiplayer games
- Offline chat
- Device-to-device pairing
- Nearby collaboration tools
- Prototyping peer-to-peer experiences

---

## TL;DR

1. **Host** waits
2. **Client** scans
3. **Client** sends invite
4. **Host** `accept()` → connected
5. `sendText` / `sendJson`

| Step | Host | Client |
|------|------|--------|
| Start | `peer.host(localUser: …)` | `peer.client(localUser: …)` |
| Find peer | waits | `nearbyHostsStream` |
| Connect | `accept()` on invite | `invite(host)` |
| Chat | `sendText` / `sendJson` | same |

---

```
Host                    Client

peer.host()             peer.client()
     │                       │
     ▼                       ▼
 Waiting               Discovering
     │                       │
     │<------ invite --------│
     │                       │
 accept()                    │
     │                       │
     └──── connected ────────┘
                │
        sendText / sendJson
```

## Quick start

Pick your role — host or client.

### Host — wait for a friend

```dart
import 'package:ble_peer_session/ble_peer_session.dart';

final peer = Peer.create(appName: 'MyGame');

final host = await peer.host(
  localUser: PeerUser(id: 'me', displayName: 'Alice'),
);

host.messagesStream.listen((message) {
  if (message.type == PeerMessageTypes.sessionInvite) host.accept();
});

host.textMessages.listen(print);
await host.sendText('Room is ready');
```

### Client — find host and say hello

```dart
import 'package:ble_peer_session/ble_peer_session.dart';

final peer = Peer.create(appName: 'MyGame');

final client = await peer.client(
  localUser: PeerUser(id: 'me', displayName: 'Bob'),
);

client.nearbyHostsStream.listen((hosts) {
  if (hosts.isEmpty) return;
  client.invite(hosts.first);
});

client.textMessages.listen(print);
await client.sendText('Hello!');
```

### Setup

```dart
final peer = Peer.create(appName: 'MyGame');

// Optional: check Bluetooth before starting
if (peer.adapterStatus == PeerAdapterStatus.disabled) {
  // show "Enable Bluetooth" UI
}

// Android 12+
await peer.permissions.checkPermissions();
```

---

## Core model

Think in **people and invitations**, not BLE.

1. Host waits.
2. Client discovers hosts.
3. Client sends invite.
4. Host accepts.
5. Both sides exchange messages.

Advertising, GATT and framing are handled internally.

### Common misconception

This is **not** a socket connection. It is an invitation-based session over BLE advertising + GATT.

Phases (`connectionStream` → `PeerConnectionPhase`):

- `waitingForPeer` — host advertising / client browsing
- `awaitingUserDecision` — host sees invite, call `accept()` or `reject()`
- `awaitingRemoteDecision` — client sent invite, waiting
- `connected` — send messages

### Design principles

- People-first (host / client)
- No BLE exposure in the basic API
- Opinionated defaults

---

## API (Level 1)

Recommended for most apps:

- `Peer.create(appName: 'MyGame')`
- `peer.host(localUser: …)` / `peer.client(localUser: …)`
- `sendText()` / `textMessages`
- `sendJson(type, map)` / `jsonMessages`

Identity: `PeerUser(id: '…', displayName: '…')`. Nearby host: `PeerNearby` in `nearbyHostsStream`.

---

## Advanced API (Level 2)

Only if you need control over UUIDs or raw BLE transport.

**Advanced features**

- Custom UUIDs
- Raw endpoints
- Direct device connections
- Custom `PeerMessage` payloads

```dart
final peer = Peer.create(
  config: BlePeerConfig(
    appName: 'MyGame',
    serviceUuid: '0000180d-0000-1000-8000-00805f9b34fb',
    characteristicUuid: '00002a37-0000-1000-8000-00805f9b34fb',
  ),
  logger: myLogger,
);
```

- Wire endpoint — `startWithEndpoint` / `startDiscoveryWithEndpoint`
- Raw device — `connect(device)`
- Any payload — `PeerMessage.app(type: '…', payload: …)`
- Session types — `PeerMessageTypes.sessionInvite`, etc.

Custom app messages:

```dart
await host.sendJson('game.move', {'row': 1, 'column': 2});

// Or full control
await host.send(
  PeerMessage.app(
    sender: host.localEndpoint!,
    type: 'game.move',
    payload: {'row': 1, 'column': 2},
  ),
);
```

Reserved session types (`PeerMessageTypes.*`) are handled automatically during handshake.

---

## Platform setup

### Android

**Required permissions** — add to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
```

**Common issue:** if discovery doesn't work, check location and Bluetooth permissions on Android 12+ (`await peer.permissions.checkPermissions()`).

### Bluetooth adapter

The package **does not** turn Bluetooth on. Observe status and guide the user:

```dart
peer.adapterStatusStream.listen((status) {
  switch (status) {
    case PeerAdapterStatus.disabled:
      // prompt user
    case PeerAdapterStatus.enabled:
      // ready
    default:
      break;
  }
});
```

---

## Example app

`example/minimal_chat` demonstrates host/client roles and text chat with zero custom UUID setup.

```bash
cd example/minimal_chat
flutter pub get
flutter run
```

On two physical devices:

1. Install the app on both phones and grant Bluetooth permissions.
2. Device A: **Host — wait for friend**.
3. Device B: **Client — find host**, tap the discovered host.
4. Host auto-accepts the invite; send messages both ways.

Same `appName` (`MinimalChat` in the example) is required so both sides share service UUIDs.

---

## Errors

All failures throw `PeerException` with `PeerErrorCode`. See [doc/ERROR_CODES.md](doc/ERROR_CODES.md).

---

## Internals (for contributors)

You don't need the sections below unless you implement a custom client or debug BLE issues.

```
Advertising
      │
      ▼
Discovery
      │
      ▼
GATT Connection
      │
      ▼
Framed Messages
      │
      ▼
JSON Payloads
```

### Message framing

One GATT write/notify carries one **frame**. Logical JSON messages larger than the effective MTU are split automatically on the link layer — you do not need to chunk in app code.

| Limit | Default |
|-------|---------|
| Chunk payload | 480 bytes |
| Max logical message | 256 KiB |

Oversized sends throw `PeerException` with `PeerErrorCode.payloadTooLarge`. Corrupt or incomplete frames emit `PeerErrorCode.messageDecodeFailed`.

Wire layout (big-endian):

```
[version:1][flags:1][messageId:2][chunkIndex:2][totalChunks:2][payload…]
```

Legacy peers that send raw JSON without the framing header (`version != 0x01`) are still accepted on receive.

---

## Migration guides

- [Documentation index](doc/README.md)
- [0.1.x → 0.2.0](doc/MIGRATION.md)
- [0.2.x → 0.3.0](doc/MIGRATION_0.3.md)

---

## License

MIT
