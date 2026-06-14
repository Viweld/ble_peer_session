import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../domain/models/peer_adapter_status.dart';

/// Maps platform Bluetooth adapter state to [PeerAdapterStatus].
abstract final class PeerAdapterMapper {
  static PeerAdapterStatus fromFlutterBluePlus(BluetoothAdapterState state) {
    return switch (state) {
      BluetoothAdapterState.unknown => PeerAdapterStatus.unknown,
      BluetoothAdapterState.unavailable => PeerAdapterStatus.unsupported,
      BluetoothAdapterState.unauthorized => PeerAdapterStatus.unauthorized,
      BluetoothAdapterState.off => PeerAdapterStatus.disabled,
      BluetoothAdapterState.on => PeerAdapterStatus.enabled,
      BluetoothAdapterState.turningOn ||
      BluetoothAdapterState.turningOff => PeerAdapterStatus.unknown,
    };
  }
}
