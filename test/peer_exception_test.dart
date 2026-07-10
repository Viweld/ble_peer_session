import 'package:ble_peer_session/src/domain/exceptions/peer_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PeerException toString includes code and cause', () {
    final PeerException exception = PeerException(
      PeerErrorCode.messageSendFailed,
      cause: StateError('write failed'),
    );

    expect(exception.toString(), contains('messageSendFailed'));
    expect(exception.toString(), contains('write failed'));
  });

  test('throwPeer throws PeerException with code', () {
    expect(
      () => throwPeer(PeerErrorCode.sessionNotConnected),
      throwsA(
        isA<PeerException>().having(
          (PeerException e) => e.code,
          'code',
          PeerErrorCode.sessionNotConnected,
        ),
      ),
    );
  });
}
