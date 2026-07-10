import 'package:meta/meta.dart';

import 'device.dart';
import 'peer_endpoint.dart';
import 'peer_identity.dart';

/// The local or remote player visible to your app (not a BLE/GATT concept).
@immutable
final class PeerUser {
  const PeerUser({required this.id, required this.displayName, this.deviceLabel});

  final String id;
  final String displayName;

  /// Shown to nearby devices during advertising. Defaults to [displayName].
  final String? deviceLabel;

  /// Builds the wire [PeerEndpoint] used internally by the transport layer.
  PeerEndpoint toEndpoint({String? deviceId}) {
    return PeerEndpoint(
      identity: PeerIdentity(id: id, displayName: displayName),
      device: Device(id: deviceId ?? id, name: deviceLabel ?? displayName, isOurApp: true),
    );
  }

  factory PeerUser.fromEndpoint(PeerEndpoint endpoint) {
    return PeerUser(
      id: endpoint.identity.id,
      displayName: endpoint.identity.displayName,
      deviceLabel: endpoint.device.name,
    );
  }
}
