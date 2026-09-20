# Migrating to 0.5.0

0.4.x was a Dart package. 0.5.0 is a Flutter plugin with an **optional** Android connected-device foreground service.

Existing `Peer.create(appName: …)` / `BlePeerConfig(...)` without `androidForeground` keeps previous behavior: no FGS.

## Enable Android foreground retention

```dart
Peer.create(
  config: BlePeerConfig(
    appName: 'MyApp',
    serviceUuid: '...',
    characteristicUuid: '...',
    androidForeground: BleAndroidForegroundConfig(
      title: 'MyApp',
      smallIcon: '@drawable/ic_stat_my_app',
    ),
  ),
);
```

Host responsibilities: notification branding, `POST_NOTIFICATIONS` UX. The plugin owns start/stop, task-removal teardown, and zombie reconciliation on `Peer.create`.

## Discovery

Treat `nearbyHostsStream` as the current nearby set. Do not union snapshots in the app.

## Connect cancel

Call `PeerClient.cancelPendingConnection()` when the user dismisses an in-flight invite. Do not wait for the GATT timeout.
