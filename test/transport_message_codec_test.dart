import 'package:ble_peer_session/ble_peer_session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ble_peer_session/src/codec/transport_message_codec.dart';
import 'package:ble_peer_session/src/domain/internal/transport_message.dart';

void main() {
  const codec = TransportMessageCodec();

  final peer = PeerEndpoint(
    identity: PeerIdentity(id: 'u1', displayName: 'Alice'),
    device: Device(id: 'd1', name: 'Phone', isOurApp: true),
  );

  test('session invitation roundtrip', () {
    final message = InvitationMessage(peerEndpoint: peer);
    final json = codec.encode(message);
    final decoded = codec.decode(json);

    expect(decoded, isA<InvitationMessage>());
    expect(decoded.peerEndpoint.identity.displayName, 'Alice');
  });

  test('app message roundtrip', () {
    final message = AppTransportMessage(
      peerEndpoint: peer,
      type: 'game.move',
      payload: {'row': 1, 'column': 2},
    );
    final decoded = codec.decode(codec.encode(message));

    expect(decoded, isA<AppTransportMessage>());
    final appMessage = decoded as AppTransportMessage;
    expect(appMessage.type, 'game.move');
    expect(appMessage.payload?['row'], 1);
  });
}
