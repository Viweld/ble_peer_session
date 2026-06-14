import 'package:permission_handler/permission_handler.dart';

import '../../domain/exceptions/peer_exception.dart';
import '../../domain/services/bluetooth_permissions_service.dart';
import 'bluetooth_permissions_utils.dart';

final class BluetoothPermissionsServiceImpl implements BluetoothPermissionsService {
  @override
  Future<bool> checkPermissions() async {
    var allGranted = await BluetoothPermissionsUtils.checkPermissions();
    if (allGranted) return true;

    final status = await BluetoothPermissionsUtils.requestPermissions();
    allGranted = status.isGranted;

    if (status.isPermanentlyDenied) {
      if (await BluetoothPermissionsUtils.openAppSettingsSafe()) {
        throwPeer(PeerErrorCode.permissionsPermanentlyDenied);
      }
      throwPeer(PeerErrorCode.permissionsDenied);
    }

    if (status.isDenied) {
      throwPeer(PeerErrorCode.permissionsDenied);
    }

    return allGranted;
  }

  @override
  Future<bool> openAppSettings() => BluetoothPermissionsUtils.openAppSettingsSafe();
}
