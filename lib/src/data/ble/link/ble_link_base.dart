import 'dart:async';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/foundation.dart';

import '../../../codec/ble_frame_codec.dart';
import '../../../domain/exceptions/peer_exception.dart';
import '../../../domain/transport/transport_link.dart';

abstract base class BleLinkBase implements TransportLink {
  BleLinkBase({
    required this.appName,
    required String serviceId,
    required String characteristicId,
    BleFrameCodec frameCodec = const BleFrameCodec(),
  }) : serviceUuid = UUID.fromString(serviceId),
       characteristicUuid = UUID.fromString(characteristicId),
       _frameCodec = frameCodec {
    _linkLostController = StreamController<void>.broadcast();
  }

  @override
  Stream<Uint8List> get incomingRawMessageStream => _incomingRawMessageController.stream;

  @override
  Stream<void> get linkLostStream => _linkLostController.stream;

  @override
  bool get isPhysicallyConnected => false;

  @override
  Future<void> sendRawMessage(Uint8List data) async {
    if (data.length > _frameCodec.maxMessageSize) {
      throwPeer(PeerErrorCode.payloadTooLarge);
    }

    final int messageId = _nextOutgoingMessageId();
    final List<Uint8List> frames = _frameCodec.fragment(data, messageId: messageId);
    for (final Uint8List frame in frames) {
      await sendPhysicalFrame(frame);
    }
  }

  @override
  Future<void> dispose() async {
    await onDispose();
    _frameAssembler.reset();
    await _incomingRawMessageController.close();
    await _linkLostController.close();
  }

  final _incomingRawMessageController = StreamController<Uint8List>.broadcast();
  late final StreamController<void> _linkLostController;
  final BleFrameCodec _frameCodec;
  final BleFrameAssembler _frameAssembler = BleFrameAssembler();
  int _outgoingMessageId = 0;
  bool _intentionalDisconnect = false;

  @protected
  final UUID serviceUuid;

  @protected
  final UUID characteristicUuid;

  @protected
  final String appName;

  @protected
  bool get intentionalDisconnect => _intentionalDisconnect;

  @protected
  void beginIntentionalDisconnect() {
    _intentionalDisconnect = true;
  }

  @protected
  void resetIntentionalDisconnect() {
    _intentionalDisconnect = false;
  }

  @protected
  void emitLinkLost() {
    if (_intentionalDisconnect || _linkLostController.isClosed) return;
    _linkLostController.add(null);
  }

  /// Sends one physical BLE frame (already framed by [sendRawMessage]).
  @protected
  Future<void> sendPhysicalFrame(Uint8List frame);

  @protected
  void translateIncomingData(Uint8List value) {
    if (_incomingRawMessageController.isClosed) return;

    final Uint8List? completeMessage = _frameAssembler.addFrame(value);
    if (completeMessage == null) {
      return;
    }

    _incomingRawMessageController.add(completeMessage);
  }

  int _nextOutgoingMessageId() {
    _outgoingMessageId = (_outgoingMessageId + 1) & 0xFFFF;
    return _outgoingMessageId;
  }

  @protected
  Future<void> onDispose();
}
