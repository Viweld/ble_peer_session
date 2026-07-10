import 'package:ble_peer_session/src/data/ble/session/session_heartbeat_send.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sendSessionHeartbeat completes when send succeeds', () async {
    var sendCount = 0;

    await sendSessionHeartbeat(() async {
      sendCount++;
    });

    expect(sendCount, 1);
  });

  test('sendSessionHeartbeat swallows send failures', () async {
    await expectLater(
      sendSessionHeartbeat(() async {
        throw StateError('GATT write queue full');
      }),
      completes,
    );
  });
}
