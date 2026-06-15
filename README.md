# ble_peer_session

> Offline 1:1 peer sessions over BLE (host / client model)

**Scope:** 1:1 only (one host + one client). No Wi‑Fi or internet required.

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

### Common misconception

This is **not** a socket connection. It is an invitation-based session over BLE advertising + GATT.

### Design principles

- People-first (host / client)
- No BLE exposure in the basic API
- Opinionated defaults

---

## Table of contents

1. [Quick start](#1-quick-start)
2. [Core model](#2-core-model)
3. [API (Level 1)](#3-api-level-1)
4. [Advanced API (Level 2)](#4-advanced-api-level-2)
5. [Platform setup](#5-platform-setup)
6. [Internals](#6-internals-for-contributors)
7. [Example app](#example-app)
8. [Migration guides](#migration-guides)

---

## 1. Quick start

### Minimal chat (end-to-end)

One complete flow — host, client, messaging both ways:

```dart
import 'package:ble_peer_session/ble_peer_session.dart';

final peer = Peer.create(appName: 'MyGame');

// --- Host (device A) ---
final host = await peer.host(
  localUser: PeerUser(id: 'alice', displayName: 'Alice'),
);

host.messagesStream.listen((message) {
  if (message.type == PeerMessageTypes.sessionInvite) host.accept();
});

host.textMessages.listen(print);
await host.sendText('Room is ready');

// --- Client (device B) ---
final client = await peer.client(
  localUser: PeerUser(id: 'bob', displayName: 'Bob'),
);

client.nearbyHostsStream.listen((hosts) {
  if (hosts.isEmpty) return;
  client.invite(hosts.first);
});

client.textMessages.listen(print);
await client.sendText('Hello!');
```

### Split into pieces

**Host — wait for a friend**

```dart
final peer = Peer.create(appName: 'MyGame');

final host = await peer.host(
  localUser: PeerUser(id: 'me', displayName: 'Alice'),
);

host.messagesStream.listen((message) {
  if (message.type == PeerMessageTypes.sessionInvite) host.accept();
});

host.textMessages.listen(print);
```

**Client — find host and say hello**

```dart
final peer = Peer.create(appName: 'MyGame');

final client = await peer.client(
  localUser: PeerUser(id: 'me', displayName: 'Bob'),
);

client.nearbyHostsStream.listen((hosts) {
  if (hosts.isEmpty) return;
  client.invite(hosts.first);
});

client.textMessages.listen(print);
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

## 2. Core model

Think in **people and invitations**, not BLE. The host advertises and waits; the client scans for nearby hosts and sends an invite. When the host accepts, both sides are connected and can exchange messages. Under the hood: advertising, GATT, JSON frames — you never need to touch that for basic use.

### Connection flow (deep dive)

```mermaid
sequenceDiagram
  participant Host
  participant Client

  Host->>Host: peer.host(localUser)
  Client->>Client: peer.client(localUser)
  Client->>Host: invite(host)
  Note over Host: sessionInvite message
  Host->>Client: accept()
  Note over Host,Client: connected
  Client->>Host: sendText("Hello")
```

Phases (`connectionStream` → `PeerConnectionPhase`):

- `waitingForPeer` — host advertising / client browsing
- `awaitingUserDecision` — host sees invite, call `accept()` or `reject()`
- `awaitingRemoteDecision` — client sent invite, waiting
- `connected` — send messages

---

## 3. API (Level 1)

Recommended for most apps:

- `Peer.create(appName: 'MyGame')` — entry point; UUIDs generated automatically
- `peer.host(localUser: …)` / `peer.client(localUser: …)` — start a session
- `sendText()` / `textMessages` — plain text chat
- `sendJson(type, map)` / `jsonMessages` — typed game or app payloads

Identity: `PeerUser(id: '…', displayName: '…')`. Nearby host: `PeerNearby` in `nearbyHostsStream`.

---

## 4. Advanced API (Level 2)

Only if you need control over UUIDs or raw BLE transport.

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

| Escape hatch | API |
|--------------|-----|
| Wire endpoint | `startWithEndpoint` / `startDiscoveryWithEndpoint` |
| Raw device | `connect(device)` |
| Any payload | `PeerMessage.app(type: '…', payload: …)` |
| Session types | `PeerMessageTypes.sessionInvite`, etc. |

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

## 5. Platform setup

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

## 6. Internals (for contributors)

You don't need the sections below unless you implement a custom client or debug BLE issues.

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

### Errors

All failures throw `PeerException` with `PeerErrorCode`. See [doc/ERROR_CODES.md](doc/ERROR_CODES.md).

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

## Migration guides

- [Documentation index](doc/README.md)
- [0.1.x → 0.2.0](doc/MIGRATION.md)
- [0.2.x → 0.3.0](doc/MIGRATION_0.3.md)

---

## License

MIT
