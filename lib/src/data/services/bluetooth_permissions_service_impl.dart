import 'package:permission_handler/permission_handler.dart';

import '../../domain/services/bluetooth_permissions_service.dart';
import 'bluetooth_permissions_utils.dart';

final class BluetoothPermissionsServiceImpl
    implements BluetoothPermissionsService {
  @override
  Future<bool> checkPermissions() async {
    var allGranted = await BluetoothPermissionsUtils.checkPermissions();
    if (allGranted) return true;

    final status = await BluetoothPermissionsUtils.requestPermissions();
    allGranted = status.isGranted;

    if (status.isPermanentlyDenied) {
      if (await BluetoothPermissionsUtils.openAppSettingsSafe()) {
        throw Exception(
          'Предоставьте разрешения Bluetooth в настройках и перезапустите приложение.',
        );
      }
      throw Exception('Разрешения Bluetooth не предоставлены.');
    }

    if (status.isDenied) {
      throw Exception('Разрешения Bluetooth не предоставлены.');
    }

    return allGranted;
  }

  @override
  Future<bool> openAppSettings() =>
      BluetoothPermissionsUtils.openAppSettingsSafe();
}
