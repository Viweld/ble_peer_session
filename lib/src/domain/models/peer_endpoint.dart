import 'package:meta/meta.dart';

import 'device.dart';
import 'peer_identity.dart';

@immutable
final class PeerEndpoint {
  const PeerEndpoint({
    required this.identity,
    required this.device,
  });

  final PeerIdentity identity;
  final Device device;
}
