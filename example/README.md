# ble_peer_session example

Minimal BLE chat: one device hosts, another scans and connects. No internet required.

## Run on a device

The runnable Flutter app with Android/iOS/macOS targets lives in [`minimal_chat/`](minimal_chat/).
Use two physical devices (BLE does not work reliably in emulators).

```bash
cd minimal_chat
flutter pub get
flutter run
```

## API sketch

```dart
import 'package:ble_peer_session/ble_peer_session.dart';

final peer = Peer.create(appName: 'MyApp');
await peer.permissions.checkPermissions();

// Host
final host = await peer.host(localUser: PeerUser(id: 'me', displayName: 'Alice'));
await for (final message in host.messagesStream) {
  if (message.type == PeerMessageTypes.sessionInvite) {
    await host.accept();
  }
}
await host.sendText('Hello!');

// Client
final client = await peer.client(localUser: PeerUser(id: 'me', displayName: 'Bob'));
await for (final nearby in client.nearbyHostsStream) {
  if (nearby.isNotEmpty) {
    await client.invite(nearby.first);
    break;
  }
}
await client.sendText('Hi!');
```

See [`lib/main.dart`](lib/main.dart) for a self-contained Flutter UI demo.
