import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/services/bluetooth_state_service.dart';
import 'bluetooth_enable_panel_util.dart';

final class BluetoothStateServiceImpl implements BluetoothStateService {
  @override
  Future<bool> isBluetoothEnabled() async {
    final state = FlutterBluePlus.adapterStateNow;
    return state != BluetoothAdapterState.off;
  }

  @override
  Future<bool> enableBluetooth() async {
    if (await isBluetoothEnabled()) return true;
    if (!kIsWeb && Platform.isAndroid) {
      await FlutterBluePlus.turnOn().catchError((_) {});
    }
    await Future<void>.delayed(const Duration(seconds: 1));
    if (await isBluetoothEnabled()) return true;
    await _openBluetoothSettings();
    await Future<void>.delayed(const Duration(seconds: 2));
    return isBluetoothEnabled();
  }

  Future<void> _openBluetoothSettings() async {
    if (Platform.isAndroid) {
      await BluetoothEnablePanelUtil.open();
    } else if (Platform.isIOS) {
      await launchUrl(Uri.parse('App-Prefs:root=Bluetooth'));
    }
  }
}
