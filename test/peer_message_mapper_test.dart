import 'package:ble_peer_session/ble_peer_session.dart';
import 'package:ble_peer_session/src/domain/internal/transport_message.dart';
import 'package:ble_peer_session/src/domain/mappers/peer_message_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final PeerEndpoint endpoint = PeerEndpoint(
    identity: const PeerIdentity(id: 'peer-1', displayName: 'Alice'),
    device: const Device(id: 'dev-1', name: 'Phone', isOurApp: true),
  );

  group('PeerMessageMapper', () {
    test('round-trips session invitation messages', () {
      final TransportMessage transport = PeerMessageMapper.toTransport(
        PeerMessage(sender: endpoint, type: PeerMessageTypes.sessionInvite),
      );
      final PeerMessage public = PeerMessageMapper.fromTransport(transport);

      expect(public.type, PeerMessageTypes.sessionInvite);
      expect(public.sender.identity.displayName, 'Alice');
    });

    test('round-trips app transport messages', () {
      final TransportMessage transport = PeerMessageMapper.toTransport(
        PeerMessage(
          sender: endpoint,
          type: 'game.move',
          payload: const <String, Object?>{'row': 1},
        ),
      );
      final PeerMessage public = PeerMessageMapper.fromTransport(transport);

      expect(public.type, 'game.move');
      expect(public.payload?['row'], 1);
    });

    test('rejects heartbeat messages on public mapping', () {
      expect(
        () => PeerMessageMapper.fromTransport(
          HeartbeatPingMessage(peerEndpoint: endpoint),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
