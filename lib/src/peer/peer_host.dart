import '../domain/mappers/peer_connection_mapper.dart';
import '../domain/mappers/peer_message_mapper.dart';
import '../domain/models/peer_connection_phase.dart';
import '../domain/models/peer_endpoint.dart';
import '../domain/models/peer_message.dart';
import '../domain/transport/transport_facade.dart';
import '../domain/transport/transport_session_server.dart';

/// Host side of a 1:1 BLE peer session (advertises and accepts connections).
abstract interface class PeerHost {
  Stream<PeerConnectionInfo?> get connectionStream;

  Stream<PeerMessage> get messagesStream;

  Future<void> start({required PeerEndpoint localPeer});

  Future<void> stop();

  Future<void> accept();

  Future<void> reject();

  Future<void> send(PeerMessage message);

  Future<void> disconnect();
}

final class PeerHostImpl implements PeerHost {
  PeerHostImpl({required TransportFacade facade, required TransportSessionServer server})
    : _facade = facade,
      _server = server;

  final TransportFacade _facade;
  final TransportSessionServer _server;

  @override
  Stream<PeerConnectionInfo?> get connectionStream =>
      _facade.connectionStateStream.map(PeerConnectionMapper.fromSessionState);

  @override
  Stream<PeerMessage> get messagesStream =>
      _facade.messagesStream.map(PeerMessageMapper.fromTransport);

  @override
  Future<void> start({required PeerEndpoint localPeer}) async {
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
