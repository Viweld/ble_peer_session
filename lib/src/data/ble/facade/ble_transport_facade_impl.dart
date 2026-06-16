import 'dart:async';

import '../../../domain/internal/transport_message.dart';
import '../../../domain/transport/models/transport_role.dart';
import '../../../domain/transport/models/transport_session_disconnect_event.dart';
import '../../../domain/transport/models/transport_session_state.dart';
import '../../../domain/transport/transport_facade.dart';
import '../../../domain/transport/transport_session.dart';
import '../../../domain/transport/transport_session_client.dart';
import '../../../domain/transport/transport_session_server.dart';

final class BleTransportFacadeImpl implements TransportFacade {
  BleTransportFacadeImpl({
    required TransportSessionClient transportSessionClient,
    required TransportSessionServer transportSessionServer,
  }) : _transportSessionClient = transportSessionClient,
       _transportSessionServer = transportSessionServer {
    _proxyMessagesStreamController = StreamController<TransportMessage>.broadcast();
    _proxyClientMessagesStreamSubscription = _clientSession.messagesStream.listen(
      _proxyMessagesStreamController.add,
    );
    _proxyServerMessagesStreamSubscription = _serverSession.messagesStream.listen(
      _proxyMessagesStreamController.add,
    );

    _proxyConnectionStateStreamController = StreamController<TransportSessionState>.broadcast();
    _proxyClientConnectionStateStreamSubscription = _clientSession.connectionStateStream.listen(
      _proxyConnectionStateStreamController.add,
    );
    _proxyServerConnectionStateStreamSubscription = _serverSession.connectionStateStream.listen(
      _proxyConnectionStateStreamController.add,
    );

    _proxyDisconnectEventStreamController =
        StreamController<TransportSessionDisconnectEvent>.broadcast();
    _proxyClientDisconnectEventStreamSubscription = _clientSession.disconnectEventStream.listen(
      _proxyDisconnectEventStreamController.add,
    );
    _proxyServerDisconnectEventStreamSubscription = _serverSession.disconnectEventStream.listen(
      _proxyDisconnectEventStreamController.add,
    );
  }

  final TransportSessionClient _transportSessionClient;
  final TransportSessionServer _transportSessionServer;
  TransportRole _role = TransportRole.server;

  TransportSession get _clientSession => _transportSessionClient as TransportSession;

  TransportSession get _serverSession => _transportSessionServer as TransportSession;

  late final StreamController<TransportMessage> _proxyMessagesStreamController;
  late final StreamSubscription<TransportMessage> _proxyClientMessagesStreamSubscription;
  late final StreamSubscription<TransportMessage> _proxyServerMessagesStreamSubscription;

  late final StreamController<TransportSessionState> _proxyConnectionStateStreamController;
  late final StreamSubscription<TransportSessionState>
  _proxyClientConnectionStateStreamSubscription;
  late final StreamSubscription<TransportSessionState>
  _proxyServerConnectionStateStreamSubscription;

  late final StreamController<TransportSessionDisconnectEvent>
  _proxyDisconnectEventStreamController;
  late final StreamSubscription<TransportSessionDisconnectEvent>
  _proxyClientDisconnectEventStreamSubscription;
  late final StreamSubscription<TransportSessionDisconnectEvent>
  _proxyServerDisconnectEventStreamSubscription;

  @override
  Stream<TransportMessage> get messagesStream => _proxyMessagesStreamController.stream;

  @override
  Stream<TransportSessionState> get connectionStateStream =>
      _proxyConnectionStateStreamController.stream;

  @override
  Stream<TransportSessionDisconnectEvent> get disconnectEventStream =>
      _proxyDisconnectEventStreamController.stream;

  @override
  Future<void> sendMessage(TransportMessage message) => transportSession.sendMessage(message);

  @override
  TransportSession get transportSession => switch (_role) {
    TransportRole.client => _clientSession,
    TransportRole.server => _serverSession,
  };

  @override
  Future<TransportSessionClient> startClientTransportSession() async {
    await _resetSessionForRole(_role);
    _role = TransportRole.client;
    return _transportSessionClient;
  }

  @override
  Future<TransportSessionServer> startServerTransportSession() async {
    await _resetSessionForRole(_role);
    _role = TransportRole.server;
    return _transportSessionServer;
  }

  Future<void> _resetSessionForRole(TransportRole role) async {
    final TransportSession session = switch (role) {
      TransportRole.client => _clientSession,
      TransportRole.server => _serverSession,
    };
    if (session.currentConnectionState == null) return;
    await session.disconnect();
  }

  @override
  Future<void> dispose() async {
    await _proxyClientMessagesStreamSubscription.cancel();
    await _proxyServerMessagesStreamSubscription.cancel();
    await _proxyMessagesStreamController.close();
    await _proxyClientConnectionStateStreamSubscription.cancel();
    await _proxyServerConnectionStateStreamSubscription.cancel();
    await _proxyConnectionStateStreamController.close();
    await _proxyClientDisconnectEventStreamSubscription.cancel();
    await _proxyServerDisconnectEventStreamSubscription.cancel();
    await _proxyDisconnectEventStreamController.close();
    await _clientSession.dispose();
    await _serverSession.dispose();
  }
}
