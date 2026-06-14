import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/models/peer_endpoint.dart';
import '../../../domain/transport/models/transport_session_state.dart';
import '../../../domain/transport/transport_session.dart';

/// Shared session FSM logic for client and server implementations.
abstract base class BleSessionBase implements TransportSession {
  @override
  TransportSessionState? get currentConnectionState => _currentConnectionState;

  @override
  Stream<TransportSessionState> get connectionStateStream => _connectionStateController.stream;

  @override
  Future<void> dispose() async {
    await onDispose();
    await _connectionStateController.close();
  }

  TransportSessionState? _currentConnectionState;
  final _connectionStateController = StreamController<TransportSessionState>.broadcast();

  @protected
  PeerEndpoint get localPeer {
    final localPeer = _currentConnectionState?.localPeer;
    return localPeer ?? (throw UnsupportedError('localPeer is not initialized'));
  }

  @protected
  void initSessionState({required PeerEndpoint localPeer}) {
    _setConnectionState(TransportSessionDisconnected(localPeer: localPeer));
  }

  @protected
  void onConnectionInvitationReceived({required PeerEndpoint remotePeer}) {
    final state = _currentConnectionState;
    if (state is! TransportSessionDisconnected) {
      throw UnsupportedError('Cannot transition to AwaitingUserDecision from $state');
    }
    _setConnectionState(
      TransportSessionAwaitingUserDecision(localPeer: state.localPeer, remotePeer: remotePeer),
    );
  }

  @protected
  void onConnectionInvitationSent() {
    final state = _currentConnectionState;
    if (state is! TransportSessionDisconnected) {
      throw UnsupportedError('Cannot transition to AwaitingRemoteDecision from $state');
    }
    _setConnectionState(TransportSessionAwaitingRemoteDecision(localPeer: state.localPeer));
  }

  @protected
  void onConnectionRequestRemoteRejected() {
    final state = _currentConnectionState;
    if (state is! TransportSessionAwaitingRemoteDecision) {
      throw UnsupportedError('Cannot transition to Disconnected from $state');
    }
    _setConnectionState(TransportSessionDisconnected(localPeer: state.localPeer));
  }

  @protected
  void onConnectionRequestUserRejected() {
    final state = _currentConnectionState;
    if (state is! TransportSessionAwaitingUserDecision) {
      throw UnsupportedError('Cannot transition to Disconnected from $state');
    }
    _setConnectionState(TransportSessionDisconnected(localPeer: state.localPeer));
  }

  @protected
  void onConnectionRequestUserAccepted() {
    final state = _currentConnectionState;
    if (state is! TransportSessionAwaitingUserDecision) {
      throw UnsupportedError('Cannot transition to Connected from $state');
    }
    _setConnectionState(
      TransportSessionConnected(localPeer: state.localPeer, remotePeer: state.remotePeer),
    );
  }

  @protected
  void onConnectionRequestRemoteConfirmed({required PeerEndpoint remotePeer}) {
    final state = _currentConnectionState;
    if (state is! TransportSessionAwaitingRemoteDecision) {
      throw UnsupportedError('Cannot transition to Connected from $state');
    }
    _setConnectionState(
      TransportSessionConnected(localPeer: state.localPeer, remotePeer: remotePeer),
    );
  }

  @protected
  void onSessionDisconnected() {
    final state = _currentConnectionState;
    if (state is! TransportSessionConnected) {
      throw UnsupportedError('Cannot transition to Disconnected from $state');
    }
    _setConnectionState(TransportSessionDisconnected(localPeer: state.localPeer));
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
