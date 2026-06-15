import 'dart:async';

import '../../../domain/internal/transport_message.dart';
import '../../../domain/models/device.dart';
import '../../../domain/models/peer_disconnect_reason.dart';
import '../../../domain/models/peer_endpoint.dart';
import '../../../domain/transport/messenger.dart';
import '../../../domain/transport/models/transport_session_state.dart';
import '../../../domain/transport/transport_session_client.dart';
import '../link/ble_link_client_impl.dart';
import 'ble_session_base.dart';

final class BleSessionClientImpl extends BleSessionBase implements TransportSessionClient {
  BleSessionClientImpl({required BleLinkClientImpl link, required Messenger messenger})
    : _link = link,
      _messenger = messenger {
    bindLinkLostStream(_link.linkLostStream);
    _unhandledMessagesSubscription = _messenger.messagesStream.listen(_messagesHandler);
    _handledMessagesController = StreamController<TransportMessage>.broadcast();
  }

  final BleLinkClientImpl _link;
  final Messenger _messenger;

  late final StreamSubscription<TransportMessage> _unhandledMessagesSubscription;
  late final StreamController<TransportMessage> _handledMessagesController;

  @override
  Stream<List<Device>> get discoveredDevicesStream => _link.discoveredDevicesStream;

  @override
  Stream<TransportMessage> get messagesStream => _handledMessagesController.stream;

  @override
  Future<void> sendMessage(TransportMessage message) => _messenger.sendMessage(message);

  @override
  Future<void> startDiscovery({required PeerEndpoint localPeer}) async {
    await _link.startDiscovery();
    initSessionState(localPeer: localPeer);
  }

  @override
  Future<void> stopDiscovery() => _link.stopDiscovery();

  @override
  Future<void> refreshDiscovery() => _link.refreshDiscovery();

  @override
  Future<void> connectToDevice(Device device) async {
    await _link.connectToDevice(device);
    await _messenger.sendMessage(InvitationMessage(peerEndpoint: localPeer));
    onConnectionInvitationSent();
  }

  @override
  Future<void> disconnect() async {
    final TransportSessionState? state = currentConnectionState;
    if (state == null) return;

    switch (state) {
      case TransportSessionConnected():
        await handleConnectedDisconnect(
          PeerDisconnectReason.userDisconnect,
          sendProtocolMessage: true,
        );
      case TransportSessionAwaitingRemoteDecision():
        await _link.disconnect();
        onConnectionRequestRemoteRejected();
      case TransportSessionDisconnected():
        await stopDiscovery();
      case TransportSessionAwaitingUserDecision():
        await _link.disconnect();
        onConnectionRequestUserRejected();
    }
  }

  @override
  Future<void> sendGracefulDisconnectMessage() async {
    await _messenger.sendMessage(DisconnectionMessage(peerEndpoint: localPeer));
  }

  @override
  Future<void> tearDownPhysicalLink() => _link.disconnect();

  @override
  Future<void> sendHeartbeatPing() async {
    if (currentConnectionState is! TransportSessionConnected) return;
    await _messenger.sendMessage(HeartbeatPingMessage(peerEndpoint: localPeer));
  }

  @override
  Future<void> onDispose() async {
    await _link.dispose();
    await _messenger.dispose();
    await _unhandledMessagesSubscription.cancel();
    await _handledMessagesController.close();
  }

  Future<void> _messagesHandler(TransportMessage event) async {
    if (_handledMessagesController.isClosed) return;

    if (await _handleInternalMessage(event)) return;

    recordSessionActivity();
    _handledMessagesController.add(event);

    switch (event) {
      case RejectionMessage():
        await _link.disconnect();
        onConnectionRequestRemoteRejected();
      case AcceptanceMessage(:final peerEndpoint):
        onConnectionRequestRemoteConfirmed(remotePeer: peerEndpoint);
      case DisconnectionMessage():
        await _link.disconnect();
        onSessionDisconnected(reason: PeerDisconnectReason.peerDisconnect);
      default:
        break;
    }
  }

  Future<bool> _handleInternalMessage(TransportMessage event) async {
    switch (event) {
      case HeartbeatPingMessage():
        recordSessionActivity();
        await _messenger.sendMessage(HeartbeatPongMessage(peerEndpoint: localPeer));
        return true;
      case HeartbeatPongMessage():
        recordSessionActivity();
        return true;
      default:
        return false;
    }
  }
}
