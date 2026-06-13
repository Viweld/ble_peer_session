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
