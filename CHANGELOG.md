## 0.3.0

- **Beginner API:** `Peer.create(appName: 'MyGame')` with auto-generated stable UUIDs (`BlePeerConfig.forApp`).
- **`PeerUser`** replaces manual `PeerEndpoint` setup for most apps; **`PeerNearby`** for discovered hosts.
- **Shortcuts:** `peer.host(localUser:)` and `peer.client(localUser:)`.
- **Client:** `invite(PeerNearby)` alias; `nearbyHostsStream` over raw devices.
- **Messaging:** `sendText()`, `textMessages`, `sendJson()`, `jsonMessages`; `PeerMessage.text` / `PeerMessage.app`.
- **`SilentLogger`** when no logger is passed.
- README: 15-second quick start examples first.
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
