import 'dart:io';

import 'package:bluetooth_low_energy_android/src/api.g.dart';
import 'package:flutter/foundation.dart';

/// Closes the Android GATT server opened by [PeripheralManager] singleton.
///
/// Required on client-only paths: [PeripheralManager] opens a GATT server when
/// Bluetooth becomes powered on, which causes dual-role conflicts on Samsung.
Future<void> closeAndroidGattServer() async {
  if (kIsWeb || !Platform.isAndroid) return;

  try {
    await PeripheralManagerHostApi().closeGATTServer();
  } on Object {
    // Best-effort cleanup during role switch or peer dispose.
  }
}
