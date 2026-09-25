import 'package:ble_peer_session/src/data/ble/link/ble_device_address.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'bluetoothAddressFromDeviceId restores a MAC from the nil-prefix UUID',
    () {
      expect(
        bluetoothAddressFromDeviceId('00000000-0000-0000-0000-7c230205a4c1'),
        '7C:23:02:05:A4:C1',
      );
    },
  );

  test('bluetoothAddressFromDeviceId keeps a colon MAC', () {
    expect(
      bluetoothAddressFromDeviceId('1c:e5:7f:03:8f:70'),
      '1C:E5:7F:03:8F:70',
    );
  });

  test('bluetoothAddressFromDeviceId rejects a service UUID', () {
    expect(
      bluetoothAddressFromDeviceId('0000a7c0-0000-1000-8000-00805f9b34fb'),
      isNull,
    );
  });
}
