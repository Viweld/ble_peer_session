## 0.4.3

- **Android:** reopen a fresh GATT server in `BleLinkServerImpl.startAdvertisingAs` before adding the service. Fixes `IllegalStateException` (`addService`) when a host session is started again after a previous host advertising was stopped and torn down (the singleton `PeripheralManager` only reopens GATT on adapter power-on transitions).

## 0.4.2

- **Android:** lazy-init `PeripheralManager` on the server link so client-only sessions do not open a GATT server at peer creation.
- **Android:** tear down GATT services and close the GATT server on server link dispose to avoid dual central/peripheral conflicts during host/client role switches (Samsung).
- **Transport:** increase post-MTU settle delay on the central link from 300ms to 500ms.

## 0.4.1

- **Pub score:** add standard `example/` layout for pub.dev (160/160 pub points).
- **Documentation:** library dartdoc and `BlePeerConfig` field comments.
- **Style:** `dart format` across `lib/` and `test/`; remove redundant `dart:typed_data` imports.

## 0.4.0

- **Transport:** GATT disconnect detection (central/peripheral connection state callbacks).
- **Transport:** Session heartbeat watchdog (5s ping, 15s inactivity timeout).
- **API:** `Peer.disconnectStream` and `PeerDisconnectReason` for unified session-end events.

## 0.3.5

- **Documentation:** fix README diagram on pub.dev — use absolute `raw.githubusercontent.com` URL (relative links break when default branch is `main`, not `master`).

## 0.3.4

- **Documentation:** replace the ASCII host/client sequence diagram in the README with an illustrated connection-flow image (`doc/assets/connection-flow.jpg`).

## 0.3.3

- **Documentation:** refined README — use cases, host/client diagrams, role-based quick start, compact core model, reordered sections (example app before errors), internals isolated for contributors.

## 0.3.2

- **Documentation:** restructured README (TL;DR first, single connection flow, grouped sections); `doc/README.md` index; updated migration guides, error codes, and `example/minimal_chat` README.

## 0.3.1

- **Framing:** logical messages larger than the BLE MTU are split and reassembled on the link layer (`BleFrameCodec`, `BleFrameAssembler`).
- **Limits:** default chunk payload 480 bytes, max logical message 256 KiB; legacy unframed payloads still accepted on receive.
- **Tests:** unit tests for fragment/reassemble, oversized payload, corrupt frames, legacy passthrough.
- **Example:** `example/minimal_chat` — host/client role picker and bidirectional text chat.

## 0.3.0

- **Beginner API:** `Peer.create(appName: 'MyGame')` with auto-generated stable UUIDs (`BlePeerConfig.forApp`).
- **`PeerUser`** replaces manual `PeerEndpoint` setup for most apps; **`PeerNearby`** for discovered hosts.
- **Shortcuts:** `peer.host(localUser:)` and `peer.client(localUser:)`.
- **Client:** `invite(PeerNearby)` alias; `nearbyHostsStream` over raw devices.
- **Messaging:** `sendText()`, `textMessages`, `sendJson()`, `jsonMessages`; `PeerMessage.text` / `PeerMessage.app`.
- **`SilentLogger`** when no logger is passed.
- README: beginner API quick start.
- 0.2 APIs preserved via `startWithEndpoint`, `connect(device)`, explicit `config`.

## 0.2.0

- **Breaking:** new public API — `Peer`, `PeerHost`, `PeerClient`, `PeerMessage`, `PeerException`, `PeerErrorCode`, `PeerConnectionPhase`, `PeerAdapterStatus`.
- **Breaking:** removed exports of `TransportFacade`, `TransportSession*`, `TransportSessionState`, session message classes, and `Bluetooth*Exception`.
- Unified errors into `PeerException` with `PeerErrorCode`.
- Adapter status via `Peer.adapterStatusStream` (no auto-enable Bluetooth).
- Documentation: mental model diagrams, connection/message flow, [ERROR_CODES.md](doc/ERROR_CODES.md), [MIGRATION.md](doc/MIGRATION.md).
- 1:1 sessions only; second central rejected at link layer.

## 0.1.2

- Fixed role switching in `BleTransportFacadeImpl`: skip `disconnect()` when the active session is uninitialized, preventing crashes on first `startClientTransportSession` / `startServerTransportSession`.
- Added state-aware `disconnect()` for client and server sessions (discovery, awaiting decision, connected).
- Added `BleLinkReadiness` to verify Bluetooth permissions and powered-on state before discovery/advertising.
- Added `BluetoothUnsupportedException`, `BluetoothPermissionsDeniedException`, and `BluetoothPeripheralUnavailableException`.
- Added tests for facade role switching.

## 0.1.1

- Removed unused dependencies (`json_annotation`, `build_runner`, `json_serializable`).
- Updated `flutter_blue_plus` and `permission_handler`.

## 0.1.0

- Initial release: BLE P2P session transport for Flutter.
- Discovery, invitation/acceptance handshake, bidirectional messaging.
- `PeerMessage` envelope for app-level payloads.
- `BlePeerSessionModule` factory and Bluetooth permission/state helpers.
