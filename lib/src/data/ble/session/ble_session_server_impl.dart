import 'dart:async';

import '../../../domain/models/peer_endpoint.dart';
import '../../../domain/internal/transport_message.dart';
import '../../../domain/transport/messenger.dart';
import '../../../domain/transport/models/transport_session_state.dart';
import '../../../domain/transport/transport_session_server.dart';
import '../link/ble_link_server_impl.dart';
import 'ble_session_base.dart';

final class BleSessionServerImpl extends BleSessionBase implements TransportSessionServer {
  BleSessionServerImpl({required BleLinkServerImpl link, required Messenger messenger})
    : _link = link,
      _messenger = messenger {
    _unhandledMessagesSubscription = _messenger.messagesStream.listen(_messagesHandler);
    _handledMessagesController = StreamController<TransportMessage>.broadcast();
  }

  final BleLinkServerImpl _link;
  final Messenger _messenger;

  late final StreamSubscription<TransportMessage> _unhandledMessagesSubscription;
  late final StreamController<TransportMessage> _handledMessagesController;

  @override
  Stream<TransportMessage> get messagesStream => _handledMessagesController.stream;

  @override
  Future<void> sendMessage(TransportMessage message) => _messenger.sendMessage(message);

  @override
  Future<void> startAdvertising({required PeerEndpoint localPeer}) async {
    await _link.startAdvertisingAs(deviceName: localPeer.device.name);
    initSessionState(localPeer: localPeer);
  }

  @override
  Future<void> stopAdvertising() => _link.stopAdvertising();

  @override
  Future<void> acceptInvitation() async {
    await _messenger.sendMessage(AcceptanceMessage(peerEndpoint: localPeer));
    onConnectionRequestUserAccepted();
  }

  @override
  Future<void> rejectInvitation() async {
    await _messenger.sendMessage(RejectionMessage(peerEndpoint: localPeer));
    await _link.disconnect();
    onConnectionRequestUserRejected();
  }

  @override
  Future<void> disconnect() async {
    final TransportSessionState? state = currentConnectionState;
    if (state == null) return;

    switch (state) {
      case TransportSessionConnected():
        await _messenger.sendMessage(DisconnectionMessage(peerEndpoint: localPeer));
        await _link.disconnect();
        onSessionDisconnected();
      case TransportSessionAwaitingUserDecision():
        await rejectInvitation();
      case TransportSessionDisconnected():
      case TransportSessionAwaitingRemoteDecision():
        await stopAdvertising();
    }
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
    _handledMessagesController.add(event);

    switch (event) {
      case InvitationMessage(:final peerEndpoint):
        onConnectionInvitationReceived(remotePeer: peerEndpoint);
      case DisconnectionMessage():
        await _link.disconnect();
        onSessionDisconnected();
      default:
        break;
    }
  }
}
