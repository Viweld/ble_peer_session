import 'package:ble_peer_session/ble_peer_session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ble_peer_session/src/config/ble_peer_uuid_generator.dart';

void main() {
  group('BlePeerUuidGenerator', () {
    test('same app name produces stable UUIDs', () {
      final first = BlePeerConfig.forApp('MyGame');
      final second = BlePeerConfig.forApp('MyGame');

      expect(first.serviceUuid, second.serviceUuid);
      expect(first.characteristicUuid, second.characteristicUuid);
      expect(first.serviceUuid, isNot(first.characteristicUuid));
    });

    test('different app names produce different UUIDs', () {
      final gameA = BlePeerConfig.forApp('GameA');
      final gameB = BlePeerConfig.forApp('GameB');

      expect(gameA.serviceUuid, isNot(gameB.serviceUuid));
    });

    test('UUID format is valid', () {
      final uuid = BlePeerUuidGenerator.uuidFor(appName: 'Test', kind: 'service');
      expect(
        uuid,
        matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')),
      );
    });
  });

  test('Peer.create resolves config from appName', () {
    final config = BlePeerConfig.forApp('Demo');
    expect(config.appName, 'Demo');
    expect(config.serviceUuid, isNotEmpty);
  });

  test('PeerUser builds endpoint for transport', () {
    const user = PeerUser(id: 'u1', displayName: 'Alice');
    final endpoint = user.toEndpoint();

    expect(endpoint.identity.displayName, 'Alice');
    expect(endpoint.device.name, 'Alice');
  });

  test('PeerMessage text factory uses appText type', () {
    const user = PeerUser(id: 'u1', displayName: 'Alice');
    final message = PeerMessage.text(sender: user.toEndpoint(), text: 'Hi');

    expect(message.type, PeerMessageTypes.appText);
    expect(message.payload?['text'], 'Hi');
  });
}
