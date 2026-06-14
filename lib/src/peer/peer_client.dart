import 'dart:async';

import '../domain/mappers/peer_connection_mapper.dart';
import '../domain/mappers/peer_message_mapper.dart';
import '../domain/models/device.dart';
import '../domain/models/peer_connection_phase.dart';
import '../domain/models/peer_endpoint.dart';
import '../domain/models/peer_message.dart';
import '../domain/transport/transport_session_client.dart';
import '../domain/transport/transport_facade.dart';

/// Client side of a 1:1 BLE peer session (discovers hosts and connects).
abstract interface class PeerClient {
  Stream<List<Device>> get discoveredDevicesStream;

  Stream<PeerConnectionInfo?> get connectionStream;

  Stream<PeerMessage> get messagesStream;

  Future<void> startDiscovery({required PeerEndpoint localPeer});

  Future<void> stopDiscovery();

  Future<void> refreshDiscovery();

  Future<void> connect(Device device);

  Future<void> send(PeerMessage message);

  Future<void> disconnect();
}

final class PeerClientImpl implements PeerClient {
  PeerClientImpl({required TransportFacade facade, required TransportSessionClient client})
    : _facade = facade,
      _client = client;

  final TransportFacade _facade;
  final TransportSessionClient _client;

  @override
  Stream<List<Device>> get discoveredDevicesStream => _client.discoveredDevicesStream;

  @override
  Stream<PeerConnectionInfo?> get connectionStream =>
      _facade.connectionStateStream.map(PeerConnectionMapper.fromSessionState);

  @override
  Stream<PeerMessage> get messagesStream =>
      _facade.messagesStream.map(PeerMessageMapper.fromTransport);

  @override
  Future<void> startDiscovery({required PeerEndpoint localPeer}) async {
    await _facade.startClientTransportSession();
    await _client.startDiscovery(localPeer: localPeer);
  }

  @override
  Future<void> stopDiscovery() => _client.stopDiscovery();

  @override
  Future<void> refreshDiscovery() => _client.refreshDiscovery();

  @override
  Future<void> connect(Device device) => _client.connectToDevice(device);

  @override
  Future<void> send(PeerMessage message) =>
      _facade.sendMessage(PeerMessageMapper.toTransport(message));

  @override
  Future<void> disconnect() => _client.disconnect();
}
