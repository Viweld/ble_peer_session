import 'package:ble_peer_session/src/data/ble/link/ble_gatt_write_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BleGattWritePolicy', () {
    test(
      'isTransientGattWriteError matches transient central write failures',
      () {
        expect(
          BleGattWritePolicy.isTransientGattWriteError(
            StateError('java.lang.IllegalStateException'),
          ),
          isTrue,
        );
        expect(
          BleGattWritePolicy.isTransientGattWriteError(
            StateError('GATT_ERROR status: 133'),
          ),
          isTrue,
        );
        expect(
          BleGattWritePolicy.isTransientGattWriteError(StateError('timeout')),
          isFalse,
        );
      },
    );

    test('isGattLinkLostError matches permanent GATT failures only', () {
      expect(
        BleGattWritePolicy.isGattLinkLostError(StateError('GATT_ERROR')),
        isTrue,
      );
      expect(
        BleGattWritePolicy.isGattLinkLostError(StateError('status: 133')),
        isTrue,
      );
      expect(
        BleGattWritePolicy.isGattLinkLostError(
          StateError('IllegalStateException'),
        ),
        isFalse,
      );
    });

    test(
      'shouldRetryWrite retries only below maxAttempts for transient errors',
      () {
        expect(
          BleGattWritePolicy.shouldRetryWrite(
            attempt: 1,
            error: StateError('IllegalStateException'),
          ),
          isTrue,
        );
        expect(
          BleGattWritePolicy.shouldRetryWrite(
            attempt: BleGattWritePolicy.maxAttempts,
            error: StateError('IllegalStateException'),
          ),
          isFalse,
        );
        expect(
          BleGattWritePolicy.shouldRetryWrite(
            attempt: 1,
            error: StateError('timeout'),
          ),
          isFalse,
        );
      },
    );
  });
}
