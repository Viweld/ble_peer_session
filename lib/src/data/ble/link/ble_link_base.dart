import 'dart:async';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/transport/transport_link.dart';

abstract base class BleLinkBase implements TransportLink {
  BleLinkBase({
    required this.appName,
    required String serviceId,
    required String characteristicId,
  }) : serviceUuid = UUID.fromString(serviceId),
       characteristicUuid = UUID.fromString(characteristicId);

  @override
  Stream<Uint8List> get incomingRawMessageStream =>
      _incomingRawMessageController.stream;

  @override
  Future<void> dispose() async {
    await onDispose();
    await _incomingRawMessageController.close();
  }

  final _incomingRawMessageController = StreamController<Uint8List>.broadcast();

  @protected
  final UUID serviceUuid;

  @protected
  final UUID characteristicUuid;

  @protected
  final String appName;

  @protected
  void translateIncomingData(Uint8List value) {
    if (_incomingRawMessageController.isClosed) return;
    _incomingRawMessageController.add(value);
  }

  @protected
  Future<void> onDispose();
}
