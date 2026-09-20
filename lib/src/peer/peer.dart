import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/ble_peer_config.dart';
import '../data/services/peer_adapter_service_impl.dart';
import '../domain/logger/logger.dart';
import '../domain/logger/silent_logger.dart';
import '../domain/mappers/peer_connection_mapper.dart';
import '../domain/mappers/peer_disconnect_mapper.dart';
import '../domain/mappers/peer_message_mapper.dart';
import '../domain/models/peer_adapter_status.dart';
import '../domain/models/peer_connection_phase.dart';
import '../domain/models/peer_disconnect_info.dart';
import '../domain/models/peer_message.dart';
import '../domain/models/peer_user.dart';
import '../domain/services/bluetooth_permissions_service.dart';
import '../module/ble_peer_session_module.dart';
import '../platform/ble_android_foreground_bridge.dart';
import '../platform/ble_android_foreground_controller.dart';
import '../platform/ble_session_retention.dart';
import 'peer_client.dart';
import 'peer_host.dart';

/// Entry point for offline BLE 1:1 peer sessions.
final class Peer {
  Peer._({
    required BlePeerSessionModule module,
    required PeerAdapterServiceImpl adapterService,
    required BleSessionRetention retention,
  }) : _module = module,
       _adapterService = adapterService,
       _retention = retention {
    _taskRemovedSubscription = _retention.taskRemoved.listen((_) {
      unawaited(_onTaskRemoved());
    });
  }

  final BlePeerSessionModule _module;
  final PeerAdapterServiceImpl _adapterService;
  final BleSessionRetention _retention;
  StreamSubscription<void>? _taskRemovedSubscription;
  bool _handlingTaskRemoved = false;

  static Peer? _foregroundOwner;

  /// Creates a [Peer] instance.
  ///
  /// Beginner-friendly:
  /// ```dart
  /// final peer = Peer.create(appName: 'MyApp');
  /// ```
  ///
  /// Advanced (custom UUIDs):
  /// ```dart
  /// final peer = Peer.create(config: myConfig, logger: myLogger);
  /// ```
  factory Peer.create({
    String? appName,
    BlePeerConfig? config,
    Logger? logger,
    String deviceNamePrefix = '',
    @visibleForTesting BleAndroidForegroundBridge? foregroundBridge,
  }) {
    if (config == null && appName == null) {
      throw ArgumentError('Provide appName or config.');
    }

    final BlePeerConfig resolvedConfig =
        config ??
        BlePeerConfig.forApp(appName!, deviceNamePrefix: deviceNamePrefix);
    final Logger resolvedLogger = logger ?? const SilentLogger();
    if (resolvedConfig.androidForeground != null && _foregroundOwner != null) {
      throw StateError(
        'Only one Peer with androidForeground is allowed per process.',
      );
    }

    final BleSessionRetention retention = _createRetention(
      config: resolvedConfig,
      bridge: foregroundBridge,
    );
    unawaited(retention.reconcile());
    final module = BlePeerSessionModule.create(
      config: resolvedConfig,
      logger: resolvedLogger,
      retention: retention,
    );
    final Peer peer = Peer._(
      module: module,
      adapterService: PeerAdapterServiceImpl(),
      retention: retention,
    );
    if (resolvedConfig.androidForeground != null) {
      _foregroundOwner = peer;
    }
    return peer;
  }

  /// Current system Bluetooth adapter status.
  PeerAdapterStatus get adapterStatus => _adapterService.currentStatus;

  /// Emits adapter status changes (disabled, unauthorized, enabled, etc.).
  Stream<PeerAdapterStatus> get adapterStatusStream =>
      _adapterService.statusStream;

  /// Emits connection lifecycle updates for the active role (host or client).
  Stream<PeerConnectionInfo?> get connectionStream => _module
      .transportFacade
      .connectionStateStream
      .map(PeerConnectionMapper.fromSessionState);

  /// Emits when an established session ends (link loss, timeout, peer/user disconnect).
  Stream<PeerDisconnectInfo> get disconnectStream => _module
      .transportFacade
      .disconnectEventStream
      .map(PeerDisconnectMapper.fromTransport);

  /// Emits all decoded messages (session handshake and application payloads).
  Stream<PeerMessage> get messagesStream => _module
      .transportFacade
      .messagesStream
      .map(PeerMessageMapper.fromTransport);

  /// Runtime permission helper for Android 12+ BLE permissions.
  BluetoothPermissionsService get permissions =>
      _module.bluetoothPermissionsService;

  /// Creates a host role session. Only one role (host or client) is active at a time.
  Future<PeerHost> createHost() async {
    return PeerHostImpl(
      facade: _module.transportFacade,
      server: _module.transportSessionServer,
    );
  }

  /// Creates a client role session. Only one role (host or client) is active at a time.
  Future<PeerClient> createClient() async {
    return PeerClientImpl(
      facade: _module.transportFacade,
      client: _module.transportSessionClient,
    );
  }

  /// Shortcut: create host and start waiting for a connection.
  Future<PeerHost> host({required PeerUser localUser}) async {
    final PeerHost session = await createHost();
    await session.start(localUser: localUser);
    return session;
  }

  /// Shortcut: create client and start scanning for nearby hosts.
  Future<PeerClient> client({required PeerUser localUser}) async {
    final PeerClient session = await createClient();
    await session.startDiscovery(localUser: localUser);
    return session;
  }

  /// Releases BLE resources held by this [Peer] instance.
  Future<void> dispose() async {
    await _taskRemovedSubscription?.cancel();
    _taskRemovedSubscription = null;
    if (identical(_foregroundOwner, this)) {
      _foregroundOwner = null;
    }
    await _retention.release();
    await _module.dispose();
  }

  @visibleForTesting
  static void resetForegroundOwnerForTest() {
    _foregroundOwner = null;
  }

  static BleSessionRetention _createRetention({
    required BlePeerConfig config,
    required BleAndroidForegroundBridge? bridge,
  }) {
    final BleAndroidForegroundConfig? foreground = config.androidForeground;
    if (foreground == null) {
      return const NoOpBleSessionRetention();
    }
    if (bridge != null) {
      return BleAndroidForegroundController(config: foreground, bridge: bridge);
    }
    if (kIsWeb || !Platform.isAndroid) {
      return const NoOpBleSessionRetention();
    }
    return BleAndroidForegroundController(
      config: foreground,
      bridge: MethodChannelBleAndroidForegroundBridge(),
    );
  }

  Future<void> _onTaskRemoved() async {
    if (_handlingTaskRemoved) return;
    _handlingTaskRemoved = true;
    try {
      await _module.tearDownForTaskRemoval();
      await _retention.release();
    } finally {
      _handlingTaskRemoved = false;
    }
  }
}
