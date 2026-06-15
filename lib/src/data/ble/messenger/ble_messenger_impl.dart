import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../../codec/transport_message_codec.dart';
import '../../../domain/internal/transport_message.dart';
import '../../../domain/logger/logger.dart';
import '../../../domain/transport/messenger.dart';
import '../link/ble_link_base.dart';

final class BleMessengerImpl implements Messenger {
  BleMessengerImpl({
    required BleLinkBase connector,
    required Logger logger,
    TransportMessageCodec codec = const TransportMessageCodec(),
  }) : _connector = connector,
       _log = logger,
       _codec = codec {
    _incomingRawMessagesSubscription = connector.incomingRawMessageStream
        .listen(_incomingRawMessagesListener);
    _incomingMessagesController =
        StreamController<TransportMessage>.broadcast();
  }

  final BleLinkBase _connector;
  final Logger _log;
  final TransportMessageCodec _codec;

  late final StreamSubscription<Uint8List> _incomingRawMessagesSubscription;
  late final StreamController<TransportMessage> _incomingMessagesController;

  @override
  Stream<TransportMessage> get messagesStream =>
      _incomingMessagesController.stream;

  @override
  Future<void> sendMessage(TransportMessage message) async {
    final json = jsonEncode(_codec.encode(message));
    final bytes = utf8.encode(json);
    await _connector.sendRawMessage(Uint8List.fromList(bytes));
  }

  @override
  Future<void> dispose() async {
    await _incomingRawMessagesSubscription.cancel();
    await _incomingMessagesController.close();
  }

  void _incomingRawMessagesListener(Uint8List event) {
    if (_incomingMessagesController.isClosed) return;
    try {
      final decoded = jsonDecode(utf8.decode(event)) as Map<String, dynamic>;
      _incomingMessagesController.add(_codec.decode(decoded));
    } catch (e) {
      _log.e('Failed to decode incoming message: $e');
    }
  }
}
