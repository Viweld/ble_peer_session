import 'package:ble_peer_session/src/domain/mappers/peer_adapter_mapper.dart';
import 'package:ble_peer_session/src/domain/models/peer_adapter_status.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PeerAdapterMapper', () {
    test('maps adapter on to enabled', () {
      expect(
        PeerAdapterMapper.fromFlutterBluePlus(BluetoothAdapterState.on),
        PeerAdapterStatus.enabled,
      );
    });

    test('maps adapter off to disabled', () {
      expect(
        PeerAdapterMapper.fromFlutterBluePlus(BluetoothAdapterState.off),
        PeerAdapterStatus.disabled,
      );
    });

    test('maps unauthorized adapter state', () {
      expect(
        PeerAdapterMapper.fromFlutterBluePlus(
          BluetoothAdapterState.unauthorized,
        ),
        PeerAdapterStatus.unauthorized,
      );
    });
  });
}
