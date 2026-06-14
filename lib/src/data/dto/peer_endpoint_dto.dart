import '../../domain/models/peer_endpoint.dart';
import 'device_dto.dart';
import 'peer_identity_dto.dart';

final class PeerEndpointDto {
  const PeerEndpointDto({required this.identity, required this.device});

  final PeerIdentityDto identity;
  final DeviceDto device;

  factory PeerEndpointDto.fromJson(Map<String, dynamic> json) => PeerEndpointDto(
    identity: PeerIdentityDto.fromJson(json['identity'] as Map<String, dynamic>),
    device: DeviceDto.fromJson(json['device'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {'identity': identity.toJson(), 'device': device.toJson()};

  PeerEndpoint toDomain() => PeerEndpoint(identity: identity.toDomain(), device: device.toDomain());

  static PeerEndpointDto fromDomain(PeerEndpoint endpoint) => PeerEndpointDto(
    identity: PeerIdentityDto.fromDomain(endpoint.identity),
    device: DeviceDto.fromDomain(endpoint.device),
  );
}
