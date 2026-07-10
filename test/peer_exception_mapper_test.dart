import 'package:ble_peer_session/src/domain/exceptions/peer_exception.dart';
import 'package:ble_peer_session/src/domain/mappers/peer_exception_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PeerExceptionMapper', () {
    test('returns existing PeerException unchanged', () {
      const PeerException original = PeerException(PeerErrorCode.discoveryFailed);

      final PeerException mapped = PeerExceptionMapper.from(original);

      expect(identical(mapped, original), isTrue);
    });

    test('maps FormatException to messageDecodeFailed', () {
      final PeerException mapped = PeerExceptionMapper.from(const FormatException('bad json'));

      expect(mapped.code, PeerErrorCode.messageDecodeFailed);
    });

    test('maps service not found platform errors', () {
      final PeerException mapped = PeerExceptionMapper.from(
        StateError('service not found for serviceUuid'),
      );

      expect(mapped.code, PeerErrorCode.serviceNotFound);
    });

    test('maps device not found platform errors', () {
      final PeerException mapped = PeerExceptionMapper.from(StateError('device not found'));

      expect(mapped.code, PeerErrorCode.deviceNotFound);
    });

    test('maps session not connected platform errors', () {
      final PeerException mapped = PeerExceptionMapper.from(StateError('sessionNotConnected'));

      expect(mapped.code, PeerErrorCode.sessionNotConnected);
    });

    test('maps GATT 133 to connectionFailed', () {
      final PeerException mapped = PeerExceptionMapper.from(StateError('status: 133'));

      expect(mapped.code, PeerErrorCode.connectionFailed);
    });

    test('maps unknown errors to unexpected', () {
      final PeerException mapped = PeerExceptionMapper.from(StateError('something else'));

      expect(mapped.code, PeerErrorCode.unexpected);
    });
  });
}
