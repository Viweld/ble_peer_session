import '../data/dto/peer_endpoint_dto.dart';
import '../domain/internal/transport_message.dart';

/// JSON codec for internal [TransportMessage] wire format.
final class TransportMessageCodec {
  const TransportMessageCodec();

  static const _typeKey = 'type';
  static const _kindKey = 'kind';
  static const _peerKey = 'peer_endpoint';
  static const _payloadKey = 'payload';
  static const _versionKey = 'v';

  Map<String, dynamic> encode(TransportMessage message) {
    final peer = PeerEndpointDto.fromDomain(message.peerEndpoint).toJson();
    return switch (message) {
      InvitationMessage() => {
        _versionKey: 1,
        _kindKey: 'session',
        _typeKey: 'invitation',
        _peerKey: peer,
      },
      AcceptanceMessage() => {
        _versionKey: 1,
        _kindKey: 'session',
        _typeKey: 'acceptance',
        _peerKey: peer,
      },
      RejectionMessage() => {
        _versionKey: 1,
        _kindKey: 'session',
        _typeKey: 'rejection',
        _peerKey: peer,
      },
      DisconnectionMessage() => {
        _versionKey: 1,
        _kindKey: 'session',
        _typeKey: 'termination',
        _peerKey: peer,
      },
      HeartbeatPingMessage() => {
        _versionKey: 1,
        _kindKey: 'session',
        _typeKey: 'heartbeat_ping',
        _peerKey: peer,
      },
      HeartbeatPongMessage() => {
        _versionKey: 1,
        _kindKey: 'session',
        _typeKey: 'heartbeat_pong',
        _peerKey: peer,
      },
      AppTransportMessage(:final type, :final payload) => {
        _versionKey: 1,
        _kindKey: 'app',
        _typeKey: type,
        _peerKey: peer,
        if (payload != null) _payloadKey: payload,
      },
    };
  }

  TransportMessage decode(Map<String, dynamic> json) {
    final peer = PeerEndpointDto.fromJson(json[_peerKey] as Map<String, dynamic>).toDomain();
    final type = json[_typeKey] as String;
    final kind = json[_kindKey] as String? ?? 'session';

    if (kind == 'app') {
      return AppTransportMessage(
        peerEndpoint: peer,
        type: type,
        payload: json[_payloadKey] as Map<String, dynamic>?,
      );
    }

    return switch (type) {
      'invitation' => InvitationMessage(peerEndpoint: peer),
      'acceptance' => AcceptanceMessage(peerEndpoint: peer),
      'rejection' => RejectionMessage(peerEndpoint: peer),
      'termination' => DisconnectionMessage(peerEndpoint: peer),
      'heartbeat_ping' => HeartbeatPingMessage(peerEndpoint: peer),
      'heartbeat_pong' => HeartbeatPongMessage(peerEndpoint: peer),
      _ => throw FormatException('Unknown session message type: $type'),
    };
  }
}
