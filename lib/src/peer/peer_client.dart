import '../domain/mappers/peer_connection_mapper.dart';
import '../domain/mappers/peer_message_mapper.dart';
import '../domain/models/device.dart';
import '../domain/models/peer_connection_phase.dart';
import '../domain/models/peer_endpoint.dart';
import '../domain/models/peer_message.dart';
import '../domain/models/peer_nearby.dart';
import '../domain/models/peer_user.dart';
import '../domain/transport/transport_session_client.dart';
import '../domain/transport/transport_facade.dart';
import 'peer_session_messaging.dart';

/// Client side of a 1:1 BLE peer session (discovers hosts and connects).
abstract interface class PeerClient implements PeerSessionMessaging {
  /// Nearby hosts found during scanning.
  Stream<List<PeerNearby>> get nearbyHostsStream;

  /// @nodoc
  Stream<List<Device>> get discoveredDevicesStream;

  Stream<PeerConnectionInfo?> get connectionStream;

  @override
  Stream<PeerMessage> get messagesStream;

  /// Starts scanning for nearby hosts.
  Future<void> startDiscovery({required PeerUser localUser});

  /// Starts scanning using a pre-built [PeerEndpoint] (advanced).
  Future<void> startDiscoveryWithEndpoint({required PeerEndpoint localPeer});

  Future<void> stopDiscovery();

  Future<void> refreshDiscovery();

  /// Connects and sends a session invite to [host].
  Future<void> invite(PeerNearby host);

  /// Connects using a raw [Device] (advanced).
  Future<void> connect(Device device);

  @override
  Future<void> send(PeerMessage message);

  Future<void> disconnect();
}

final class PeerClientImpl implements PeerClient {
  PeerClientImpl({required TransportFacade facade, required TransportSessionClient client})
    : _facade = facade,
      _client = client;

  final TransportFacade _facade;
  final TransportSessionClient _client;

  PeerEndpoint? _localEndpoint;

  @override
  PeerEndpoint? get localEndpoint => _localEndpoint;

  @override
  Stream<List<PeerNearby>> get nearbyHostsStream => _client.discoveredDevicesStream.map(
    (List<Device> devices) => devices.map(PeerNearby.fromDevice).toList(growable: false),
  );

  @override
  Stream<List<Device>> get discoveredDevicesStream => _client.discoveredDevicesStream;

  @override
  Stream<PeerConnectionInfo?> get connectionStream =>
      _facade.connectionStateStream.map(PeerConnectionMapper.fromSessionState);

  @override
  Stream<PeerMessage> get messagesStream =>
      _facade.messagesStream.map(PeerMessageMapper.fromTransport);

  @override
  Future<void> startDiscovery({required PeerUser localUser}) =>
      startDiscoveryWithEndpoint(localPeer: localUser.toEndpoint());

  @override
  Future<void> startDiscoveryWithEndpoint({required PeerEndpoint localPeer}) async {
    _localEndpoint = localPeer;
    await _facade.startClientTransportSession();
    await _client.startDiscovery(localPeer: localPeer);
  }

  @override
  Future<void> stopDiscovery() => _client.stopDiscovery();

  @override
  Future<void> refreshDiscovery() => _client.refreshDiscovery();

  @override
  Future<void> invite(PeerNearby host) => connect(host.device);

  @override
  Future<void> connect(Device device) => _client.connectToDevice(device);

  @override
  Future<void> send(PeerMessage message) =>
      _facade.sendMessage(PeerMessageMapper.toTransport(message));

  @override
  Future<void> disconnect() => _client.disconnect();
}
