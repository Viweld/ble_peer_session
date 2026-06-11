import 'package:ble_peer_session/ble_peer_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BlePeerConfig holds service identifiers', () {
    const config = BlePeerConfig(
      appName: 'Test',
      serviceUuid: '0000180d-0000-1000-8000-00805f9b34fb',
      characteristicUuid: '00002a37-0000-1000-8000-00805f9b34fb',
    );

    expect(config.appName, 'Test');
    expect(config.protocolVersion, 1);
  });
}
