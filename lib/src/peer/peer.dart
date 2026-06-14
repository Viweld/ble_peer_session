import '../config/ble_peer_config.dart';
import '../data/services/peer_adapter_service_impl.dart';
import '../domain/logger/logger.dart';
import '../domain/mappers/peer_connection_mapper.dart';
import '../domain/mappers/peer_message_mapper.dart';
import '../domain/models/peer_adapter_status.dart';
import '../domain/models/peer_connection_phase.dart';
import '../domain/models/peer_message.dart';
import '../domain/services/bluetooth_permissions_service.dart';
import '../module/ble_peer_session_module.dart';
import 'peer_client.dart';
import 'peer_host.dart';

/// Entry point for offline BLE 1:1 peer sessions.
final class Peer {
  Peer._({required BlePeerSessionModule module, required PeerAdapterServiceImpl adapterService})
    : _module = module,
      _adapterService = adapterService;

  final BlePeerSessionModule _module;
  final PeerAdapterServiceImpl _adapterService;

  /// Creates a [Peer] instance wired to the given BLE service UUIDs.
  factory Peer.create({required BlePeerConfig config, required Logger logger}) {
    final module = BlePeerSessionModule.create(config: config, logger: logger);
    return Peer._(module: module, adapterService: PeerAdapterServiceImpl());
  }

  /// Current system Bluetooth adapter status.
  PeerAdapterStatus get adapterStatus => _adapterService.currentStatus;

  /// Emits adapter status changes (disabled, unauthorized, enabled, etc.).
  Stream<PeerAdapterStatus> get adapterStatusStream => _adapterService.statusStream;

  /// Emits connection lifecycle updates for the active role (host or client).
  Stream<PeerConnectionInfo?> get connectionStream =>
      _module.transportFacade.connectionStateStream.map(PeerConnectionMapper.fromSessionState);

  /// Emits all decoded messages (session handshake and application payloads).
  Stream<PeerMessage> get messagesStream =>
      _module.transportFacade.messagesStream.map(PeerMessageMapper.fromTransport);

  /// Runtime permission helper for Android 12+ BLE permissions.
  BluetoothPermissionsService get permissions => _module.bluetoothPermissionsService;

  /// Creates a host role session. Only one role (host or client) is active at a time.
  Future<PeerHost> createHost() async {
    return PeerHostImpl(facade: _module.transportFacade, server: _module.transportSessionServer);
  }

  /// Creates a client role session. Only one role (host or client) is active at a time.
  Future<PeerClient> createClient() async {
    return PeerClientImpl(facade: _module.transportFacade, client: _module.transportSessionClient);
  }

  /// Releases BLE resources held by this [Peer] instance.
  Future<void> dispose() => _module.dispose();
}
