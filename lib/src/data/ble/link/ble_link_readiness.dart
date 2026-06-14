import 'dart:async';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../domain/exceptions/peer_exception.dart';
import '../../services/bluetooth_permissions_utils.dart';

/// Ensures runtime permissions and a powered-on BLE manager before link operations.
final class BleLinkReadiness {
  BleLinkReadiness._();

  static Future<void> ensurePermissions() async {
    if (await BluetoothPermissionsUtils.checkPermissions()) return;

    final PermissionStatus status = await BluetoothPermissionsUtils.requestPermissions();
    if (status.isGranted) return;

    throwPeer(
      status.isPermanentlyDenied
          ? PeerErrorCode.permissionsPermanentlyDenied
          : PeerErrorCode.permissionsDenied,
    );
  }

  static Future<void> ensureManagerPoweredOn(BluetoothLowEnergyManager manager) async {
    await _resolveInitialState(manager);

    if (manager.state == BluetoothLowEnergyState.poweredOn) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return;
    }

    if (manager.state == BluetoothLowEnergyState.unsupported) {
      throwPeer(PeerErrorCode.bluetoothUnsupported);
    }

    if (manager.state == BluetoothLowEnergyState.poweredOff) {
      throwPeer(PeerErrorCode.bluetoothDisabled);
    }

    final Completer<void> poweredOnCompleter = Completer<void>();
    late final StreamSubscription<BluetoothLowEnergyStateChangedEventArgs> subscription;
    subscription = manager.stateChanged.listen((BluetoothLowEnergyStateChangedEventArgs event) {
      switch (event.state) {
        case BluetoothLowEnergyState.poweredOn:
          if (!poweredOnCompleter.isCompleted) poweredOnCompleter.complete();
        case BluetoothLowEnergyState.poweredOff:
          if (!poweredOnCompleter.isCompleted) {
            poweredOnCompleter.completeError(PeerException(PeerErrorCode.bluetoothDisabled));
          }
        case BluetoothLowEnergyState.unsupported:
          if (!poweredOnCompleter.isCompleted) {
            poweredOnCompleter.completeError(PeerException(PeerErrorCode.bluetoothUnsupported));
          }
        case BluetoothLowEnergyState.unauthorized:
          if (!poweredOnCompleter.isCompleted) {
            poweredOnCompleter.completeError(PeerException(PeerErrorCode.bluetoothUnauthorized));
          }
        case BluetoothLowEnergyState.unknown:
          break;
      }
    });

    try {
      await poweredOnCompleter.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throwPeer(PeerErrorCode.adapterNotReady),
      );
      await Future<void>.delayed(const Duration(milliseconds: 250));
    } finally {
      await subscription.cancel();
    }
  }

  static Future<void> _resolveInitialState(BluetoothLowEnergyManager manager) async {
    if (manager.state == BluetoothLowEnergyState.unauthorized) {
      await manager.authorize();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }
}
