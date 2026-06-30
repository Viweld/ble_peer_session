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

/// Opens a fresh Android GATT server on the [PeripheralManager] singleton.
///
/// [PeripheralManager] only opens its GATT server on adapter power-on
/// transitions. Once the server is closed during host teardown the adapter
/// stays powered on, so a subsequent `addService` call hits the closed server
/// and throws `IllegalStateException`. Reopening here restores host advertising
/// after a previous host session was torn down.
Future<void> openAndroidGattServer() async {
  if (kIsWeb || !Platform.isAndroid) return;

  try {
    await PeripheralManagerHostApi().openGATTServer();
  } on Object {
    // Best-effort; addService surfaces failures if the server stays unavailable.
  }
}
