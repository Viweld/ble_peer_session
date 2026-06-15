# minimal_chat

End-to-end example for [ble_peer_session](../../README.md): host/client roles and bidirectional text chat with zero custom UUID setup.

---

## TL;DR

1. Run on **two physical devices** (BLE host needs a real peripheral).
2. Same `appName` on both sides (`MinimalChat` — set in `main.dart`).
3. Device A → **Host**. Device B → **Client** → tap discovered host.
4. Host auto-accepts invite; chat both ways via `sendText`.

This is **not** a socket — it is an invitation-based BLE session. See [Core model](../../README.md#2-core-model).

---

## Run

```bash
cd example/minimal_chat
flutter pub get
flutter run
```

Grant Bluetooth permissions when prompted (Android 12+: scan, connect, advertise).

---

## What the app demonstrates

| Screen | API used |
|--------|----------|
| Role picker | `Peer.create(appName: 'MinimalChat')`, `peer.permissions.checkPermissions()` |
| Host | `peer.host(localUser:)`, `messagesStream` → `accept()` on invite |
| Client | `peer.client(localUser:)`, `nearbyHostsStream`, `invite(host)` |
| Chat | `sendText()`, `textMessages`, `connectionStream` phases |

Source: single file — [`lib/main.dart`](lib/main.dart).

---

## Try it

1. Install on two phones; enter a display name on each.
2. Phone A: **Host — wait for friend**.
3. Phone B: **Client — find host**; tap the host in the list.
4. Send messages once status shows **Connected**.

**Common issues:**

- No hosts in list → enable Bluetooth on both devices; check Android permissions ([Platform setup](../../README.md#5-platform-setup)).
- Host on emulator → use a physical device for the host role (`peripheralUnavailable`).

---

## Next steps

- Package docs: [README](../../README.md)
- All guides: [doc/README.md](../../doc/README.md)
