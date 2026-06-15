import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/models/peer_disconnect_reason.dart';
import '../../../domain/models/peer_endpoint.dart';
import '../../../domain/transport/models/transport_session_disconnect_event.dart';
import '../../../domain/transport/models/transport_session_state.dart';
import '../../../domain/transport/transport_session.dart';
import '../session/session_liveness_monitor.dart';

/// Shared session FSM logic for client and server implementations.
abstract base class BleSessionBase implements TransportSession {
  BleSessionBase() {
    _disconnectEventController = StreamController<TransportSessionDisconnectEvent>.broadcast();
  }

  @override
  TransportSessionState? get currentConnectionState => _currentConnectionState;

  @override
  Stream<TransportSessionState> get connectionStateStream => _connectionStateController.stream;

  @override
  Stream<TransportSessionDisconnectEvent> get disconnectEventStream =>
      _disconnectEventController.stream;

  @override
  Future<void> dispose() async {
    _stopLivenessMonitor();
    await _linkLostSubscription?.cancel();
    await onDispose();
    await _connectionStateController.close();
    await _disconnectEventController.close();
  }

  TransportSessionState? _currentConnectionState;
  final _connectionStateController = StreamController<TransportSessionState>.broadcast();
  late final StreamController<TransportSessionDisconnectEvent> _disconnectEventController;

  SessionLivenessMonitor? _livenessMonitor;
  StreamSubscription<void>? _linkLostSubscription;
  bool _disconnectHandled = false;

  @protected
  PeerEndpoint get localPeer {
    final PeerEndpoint? localPeer = _currentConnectionState?.localPeer;
    return localPeer ?? (throw UnsupportedError('localPeer is not initialized'));
  }

  @protected
  void bindLinkLostStream(Stream<void> linkLostStream) {
    unawaited(_linkLostSubscription?.cancel());
    _linkLostSubscription = linkLostStream.listen((_) {
      unawaited(handleConnectedDisconnect(PeerDisconnectReason.linkLost, sendProtocolMessage: false));
    });
  }

  @protected
  void initSessionState({required PeerEndpoint localPeer}) {
    _disconnectHandled = false;
    _setConnectionState(TransportSessionDisconnected(localPeer: localPeer));
  }

  @protected
  void onConnectionInvitationReceived({required PeerEndpoint remotePeer}) {
    final TransportSessionState state = _currentConnectionState!;
    if (state is! TransportSessionDisconnected) {
      throw UnsupportedError('Cannot transition to AwaitingUserDecision from $state');
    }
    _setConnectionState(
      TransportSessionAwaitingUserDecision(localPeer: state.localPeer, remotePeer: remotePeer),
    );
  }

  @protected
  void onConnectionInvitationSent() {
    final TransportSessionState state = _currentConnectionState!;
    if (state is! TransportSessionDisconnected) {
      throw UnsupportedError('Cannot transition to AwaitingRemoteDecision from $state');
    }
    _setConnectionState(TransportSessionAwaitingRemoteDecision(localPeer: state.localPeer));
  }

  @protected
  void onConnectionRequestRemoteRejected() {
    final TransportSessionState state = _currentConnectionState!;
    if (state is! TransportSessionAwaitingRemoteDecision) {
      throw UnsupportedError('Cannot transition to Disconnected from $state');
    }
    _setConnectionState(TransportSessionDisconnected(localPeer: state.localPeer));
  }

  @protected
  void onConnectionRequestUserRejected() {
    final TransportSessionState state = _currentConnectionState!;
    if (state is! TransportSessionAwaitingUserDecision) {
      throw UnsupportedError('Cannot transition to Disconnected from $state');
    }
    _setConnectionState(TransportSessionDisconnected(localPeer: state.localPeer));
  }

  @protected
  void onConnectionRequestUserAccepted() {
    final TransportSessionState state = _currentConnectionState!;
    if (state is! TransportSessionAwaitingUserDecision) {
      throw UnsupportedError('Cannot transition to Connected from $state');
    }
    _enterConnected(
      localPeer: state.localPeer,
      remotePeer: state.remotePeer,
    );
  }

  @protected
  void onConnectionRequestRemoteConfirmed({required PeerEndpoint remotePeer}) {
    final TransportSessionState state = _currentConnectionState!;
    if (state is! TransportSessionAwaitingRemoteDecision) {
      throw UnsupportedError('Cannot transition to Connected from $state');
    }
    _enterConnected(localPeer: state.localPeer, remotePeer: remotePeer);
  }

  @protected
  void onSessionDisconnected({required PeerDisconnectReason reason}) {
    final TransportSessionState? state = _currentConnectionState;
    if (state is! TransportSessionConnected) return;
    if (_disconnectHandled) return;

    _disconnectHandled = true;
    _stopLivenessMonitor();

    final PeerEndpoint remotePeer = state.remotePeer;
    _setConnectionState(TransportSessionDisconnected(localPeer: state.localPeer));

    if (_disconnectEventController.isClosed) return;
    _disconnectEventController.add(
      TransportSessionDisconnectEvent(
        reason: reason,
        localPeer: state.localPeer,
        remotePeer: remotePeer,
      ),
    );
  }

  @protected
  void recordSessionActivity() {
    _livenessMonitor?.recordActivity();
  }

  @protected
  Future<void> handleConnectedDisconnect(
    PeerDisconnectReason reason, {
    required bool sendProtocolMessage,
  }) async {
    if (_currentConnectionState is! TransportSessionConnected) return;
    if (_disconnectHandled) return;

    if (sendProtocolMessage) {
      await sendGracefulDisconnectMessage();
    }

    await tearDownPhysicalLink();
    onSessionDisconnected(reason: reason);
  }

  @protected
  Future<void> sendGracefulDisconnectMessage();

  @protected
  Future<void> tearDownPhysicalLink();

  @protected
  Future<void> sendHeartbeatPing();

  void _enterConnected({required PeerEndpoint localPeer, required PeerEndpoint remotePeer}) {
    _disconnectHandled = false;
    _setConnectionState(TransportSessionConnected(localPeer: localPeer, remotePeer: remotePeer));
    _startLivenessMonitor();
  }

  void _startLivenessMonitor() {
    _stopLivenessMonitor();
    _livenessMonitor = SessionLivenessMonitor(
      onSendPing: sendHeartbeatPing,
      onTimeout: () {
        unawaited(
          handleConnectedDisconnect(PeerDisconnectReason.timeout, sendProtocolMessage: false),
        );
      },
    )..start();
  }

  void _stopLivenessMonitor() {
    _livenessMonitor?.stop();
    _livenessMonitor = null;
  }

  void _setConnectionState(TransportSessionState state) {
    if (_currentConnectionState == state) return;
    _currentConnectionState = state;
    if (_connectionStateController.isClosed) return;
    _connectionStateController.add(state);
  }

  @protected
  Future<void> onDispose();
}
