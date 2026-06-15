# Error codes

All package failures surface as `PeerException` with a `PeerErrorCode`.

See also: [main README](../README.md) · [doc index](README.md)

---

## Adapter and permissions

| Code | Typical cause | Suggested handling |
|------|---------------|-------------------|
| `bluetoothDisabled` | BT adapter is off | Prompt user to enable Bluetooth in system settings |
| `bluetoothUnsupported` | Device/emulator lacks BLE peripheral or central | Show unsupported message |
| `bluetoothUnauthorized` | OS denied BT access (iOS) | Show settings link |
| `permissionsDenied` | Android runtime permissions not granted | Call `peer.permissions.checkPermissions()` |
| `permissionsPermanentlyDenied` | User selected "Don't ask again" | Open app settings |
| `adapterNotReady` | Adapter did not reach powered-on within timeout | Retry or ask user to toggle BT |

## Link and session

| Code | Typical cause | Suggested handling |
|------|---------------|-------------------|
| `peripheralUnavailable` | GATT server failed (emulator, missing permissions) | Check permissions; use real device for host |
| `advertisingFailed` | Could not start advertising | Retry; check BT state |
| `discoveryFailed` | Scan failed to start | Check permissions and BT state |
| `deviceNotFound` | Connect target not in scan cache | Refresh discovery |
| `connectionFailed` | GATT connect or setup failed | Retry connect |
| `connectionTimeout` | Link setup timed out | Retry |
| `serviceNotFound` | Remote device lacks configured service UUID | Wrong `appName` or version on remote device |
| `characteristicNotFound` | GATT characteristic missing | Config mismatch (custom UUIDs) |
| `sessionNotConnected` | Send while link is down | Wait for `connected` phase |

## Session handshake

| Code | Typical cause | Suggested handling |
|------|---------------|-------------------|
| `remoteRejected` | Host rejected invite | Return to device list |
| `remoteDisconnected` | Peer sent disconnect | Return to idle UI |

## Messaging

| Code | Typical cause | Suggested handling |
|------|---------------|-------------------|
| `payloadTooLarge` | Logical message exceeds 256 KiB limit | Shrink payload |
| `messageEncodeFailed` | Invalid message shape | Fix app message |
| `messageDecodeFailed` | Corrupt or incomplete frame on wire | Log and ignore; see [message framing](../README.md#message-framing) |
| `messageSendFailed` | GATT write failed | Retry or disconnect |

## Lifecycle

| Code | Typical cause | Suggested handling |
|------|---------------|-------------------|
| `disposed` | Used after `peer.dispose()` | Create new `Peer` |
| `operationCancelled` | Operation aborted | No-op or retry |
| `unexpected` | Unmapped platform error | Log `cause`; generic error UI |

---

## Example

```dart
try {
  await client.invite(host);
} on PeerException catch (e) {
  switch (e.code) {
    case PeerErrorCode.permissionsDenied:
      await peer.permissions.checkPermissions();
    case PeerErrorCode.sessionNotConnected:
      // wait for connected phase
    default:
      debugPrint('${e.code}: ${e.cause}');
  }
}
```
