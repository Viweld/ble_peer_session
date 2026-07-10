import '../domain/mappers/peer_connection_mapper.dart';
import '../domain/mappers/peer_message_mapper.dart';
import '../domain/models/peer_connection_phase.dart';
import '../domain/models/peer_endpoint.dart';
import '../domain/models/peer_message.dart';
import '../domain/models/peer_user.dart';
import '../domain/transport/transport_facade.dart';
import '../domain/transport/transport_session_server.dart';
import 'peer_session_messaging.dart';

/// Host side of a 1:1 BLE peer session (advertises and accepts connections).
abstract interface class PeerHost implements PeerSessionMessaging {
  Stream<PeerConnectionInfo?> get connectionStream;

  @override
  Stream<PeerMessage> get messagesStream;

  /// Starts advertising and waiting for a client invite.
  Future<void> start({required PeerUser localUser});

  /// Starts advertising using a pre-built [PeerEndpoint] (advanced).
  Future<void> startWithEndpoint({required PeerEndpoint localPeer});

  Future<void> stop();

  Future<void> accept();

  Future<void> reject();

  @override
  Future<void> send(PeerMessage message);

  Future<void> disconnect();
}

final class PeerHostImpl implements PeerHost {
  PeerHostImpl({required TransportFacade facade, required TransportSessionServer server})
    : _facade = facade,
      _server = server;

  final TransportFacade _facade;
  final TransportSessionServer _server;

  PeerEndpoint? _localEndpoint;

  @override
  PeerEndpoint? get localEndpoint => _localEndpoint;

  @override
  Stream<PeerConnectionInfo?> get connectionStream =>
      _facade.connectionStateStream.map(PeerConnectionMapper.fromSessionState);

  @override
  Stream<PeerMessage> get messagesStream =>
      _facade.messagesStream.map(PeerMessageMapper.fromTransport);

  @override
  Future<void> start({required PeerUser localUser}) =>
      startWithEndpoint(localPeer: localUser.toEndpoint());

  @override
  Future<void> startWithEndpoint({required PeerEndpoint localPeer}) async {
    _localEndpoint = localPeer;
    await _facade.startServerTransportSession();
    await _server.startAdvertising(localPeer: localPeer);
  }

  @override
  Future<void> stop() => _server.stopAdvertising();

  @override
  Future<void> accept() => _server.acceptInvitation();

  @override
  Future<void> reject() => _server.rejectInvitation();

  @override
  Future<void> send(PeerMessage message) =>
      _facade.sendMessage(PeerMessageMapper.toTransport(message));

  @override
  Future<void> disconnect() => _server.disconnect();
}
