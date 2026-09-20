import '../../domain/models/peer_identity.dart';

final class PeerIdentityDto {
  const PeerIdentityDto({required this.id, required this.displayName});

  final String id;
  final String displayName;

  factory PeerIdentityDto.fromJson(Map<String, dynamic> json) =>
      PeerIdentityDto(
        id: json['id'] as String,
        displayName: json['display_name'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'display_name': displayName};

  PeerIdentity toDomain() => PeerIdentity(id: id, displayName: displayName);

  static PeerIdentityDto fromDomain(PeerIdentity identity) =>
      PeerIdentityDto(id: identity.id, displayName: identity.displayName);
}
