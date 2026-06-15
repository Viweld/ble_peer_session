# Migration guide: 0.2.x → 0.3.0

Version 0.3.0 adds a beginner-friendly **Level 1 API**. All 0.2 APIs still work (Level 2).

See also: [main README](../README.md) · [0.1 → 0.2 guide](MIGRATION.md) · [doc index](README.md)

---

## TL;DR

| 0.2.x | 0.3.0 (Level 1) |
|-------|-----------------|
| `Peer.create(config: …, logger: …)` | `Peer.create(appName: 'MyGame')` |
| `localPeer: PeerEndpoint` | `localUser: PeerUser` |
| `createHost()` + `start()` | `peer.host(localUser: …)` |
| `createClient()` + `startDiscovery()` | `peer.client(localUser: …)` |
| `connect(device)` | `invite(PeerNearby)` |

Keep the 0.2 API when you need custom UUIDs, raw `Device` / `PeerEndpoint`, or a custom `Logger`. See [Advanced API](../README.md#4-advanced-api-level-2).

---

## Entry point

**Before (0.2):**

```dart
final peer = Peer.create(
  config: BlePeerConfig(
    appName: 'MyGame',
    serviceUuid: '...',
    characteristicUuid: '...',
  ),
  logger: myLogger,
);
```

**After (0.3):**

```dart
final peer = Peer.create(appName: 'MyGame');
// UUIDs derived from appName — same on every device with the same app
```

---

## Host / client

**Before:**

```dart
final host = await peer.createHost();
await host.start(
  localPeer: PeerEndpoint(
    identity: PeerIdentity(id: 'u1', displayName: 'Alice'),
    device: Device(id: 'd1', name: 'AlicePhone', isOurApp: true),
  ),
);
```

**After:**

```dart
final host = await peer.host(
  localUser: PeerUser(id: 'u1', displayName: 'Alice'),
);
```

Same pattern for client: `peer.client(localUser: …)` instead of `createClient()` + `startDiscovery()`.

---

## Invite instead of connect

**Before:**

```dart
client.devicesStream.listen((devices) {
  client.connect(devices.first);
});
```

**After:**

```dart
client.nearbyHostsStream.listen((hosts) {
  if (hosts.isNotEmpty) client.invite(hosts.first);
});
```

`invite()` sends a session invitation — not a raw BLE connect. The host calls `accept()` to complete the handshake.

---

## Messaging

Level 1 shortcuts (optional — `send()` with `PeerMessage.app` still works):

```dart
await host.sendText('Hello');
host.textMessages.listen(print);

await host.sendJson('game.move', {'row': 1});
host.jsonMessages.listen((payload) { /* ... */ });
```

---

## When to keep the 0.2 API

- Custom BLE service UUIDs shared with another app or platform
- Full control over `Device` / `PeerEndpoint` wire format
- Custom `Logger` (default is silent in 0.3 when omitted)

Use `startWithEndpoint`, `startDiscoveryWithEndpoint`, and `connect(device)` — documented under [Advanced API](../README.md#4-advanced-api-level-2).
