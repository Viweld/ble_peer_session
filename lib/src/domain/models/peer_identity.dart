import 'package:meta/meta.dart';

@immutable
final class PeerIdentity {
  const PeerIdentity({required this.id, required this.displayName});

  final String id;
  final String displayName;
}
