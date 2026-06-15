# Migration guide: 0.2.x → 0.3.0

Version 0.3.0 adds a beginner-friendly API layer. **All 0.2 APIs still work.**

## Summary

| 0.2.x | 0.3.0 (recommended) | 0.2 still works |
|-------|---------------------|-----------------|
| `Peer.create(config: …, logger: …)` | `Peer.create(appName: 'MyGame')` | yes |
| `localPeer: PeerEndpoint` | `localUser: PeerUser` | `startWithEndpoint` / `startDiscoveryWithEndpoint` |
| `createHost()` + `start()` | `peer.host(localUser: …)` | yes |
| `createClient()` + `startDiscovery()` | `peer.client(localUser: …)` | yes |
| `connect(device)` | `invite(PeerNearby)` | `connect(device)` |
| `PeerMessage(type: '…', …)` | `PeerMessage.app` / `sendText()` | yes |

## Simpler entry

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
// UUIDs are derived from appName — same on every device with the same app
```

## PeerUser instead of PeerEndpoint

**Before:**

```dart
await client.startDiscovery(
  localPeer: PeerEndpoint(
    identity: PeerIdentity(id: 'u1', displayName: 'Bob'),
    device: Device(id: 'd1', name: 'BobPhone', isOurApp: true),
  ),
);
```

**After:**

```dart
await client.startDiscovery(
  localUser: PeerUser(id: 'u1', displayName: 'Bob'),
);
```

## Shortcuts

```dart
final host = await peer.host(localUser: user);
final client = await peer.client(localUser: user);
```

## Invite instead of connect

```dart
client.nearbyHostsStream.listen((hosts) {
  client.invite(hosts.first);
});
```

## High-level messaging

```dart
await host.sendText('Hello');
host.textMessages.listen(print);

await host.sendJson('game.move', {'row': 1});
host.jsonMessages.listen((payload) { /* ... */ });
```

## When to keep the 0.2 API

- Custom BLE service UUIDs shared with another app or platform
- Full control over `Device` / `PeerEndpoint` wire format
- Custom `Logger` (default is silent in 0.3 when omitted)
