# ble_peer_session

Offline BLE peer-to-peer sessions for Flutter: discovery, consent handshake, and bidirectional messaging for local games and chat.

## Scope

Works **only over BLE** — suitable for Android ↔ iOS ad-hoc communication without Wi‑Fi or internet (e.g. Samsung ↔ iPhone offline).

## Quick start

```dart
import 'package:ble_peer_session/ble_peer_session.dart';

final module = BlePeerSessionModule.create(
  config: BlePeerConfig(
    appName: 'MyApp',
    serviceUuid: '0000180d-0000-1000-8000-00805f9b34fb',
    characteristicUuid: '00002a37-0000-1000-8000-00805f9b34fb',
  ),
  logger: myLogger, // implements Logger
);

final facade = module.transportFacade;
final client = module.transportSessionClient;

await client.startDiscovery(
  localPeer: PeerEndpoint(
    identity: PeerIdentity(id: 'u1', displayName: 'Player'),
    device: Device(id: 'd1', name: 'MyPhone', isOurApp: true),
  ),
);
```

## Session messages

- `InvitationMessage` — client requests connection
- `AcceptanceMessage` / `RejectionMessage` — server response
- `DisconnectionMessage` — graceful disconnect

## App messages

Use `PeerMessage` with arbitrary `type` and `payload`:

```dart
await facade.sendMessage(
  PeerMessage(
    peerEndpoint: localPeer,
    type: 'chat.text',
    payload: {'text': 'Hello'},
  ),
);
```

## Naming convention

- Public contracts: `TransportFacade`, `Messenger`, `Logger` (no `I` prefix)
- Implementations: `BleTransportFacadeImpl`, `BleMessengerImpl` (`Impl` suffix, not exported)

## Comparison (BLE-only alternatives)

| | ble_peer_session | offline_sms |
|--|------------------|-------------|
| Consent handshake | yes | no in API |
| Session FSM | yes | basic |
| Game payload (`PeerMessage`) | yes | text only |
| Flutter package | yes | yes |

## Android host setup

For `BluetoothStateServiceImpl` on Android, register MethodChannel `bluetooth_channel` in `MainActivity` (see batuga app example).

## Backlog

См. [BACKLOG.md](BACKLOG.md) — `example/minimal_chat`, framing > MTU (v0.2) и следующие задачи.

## License

MIT
