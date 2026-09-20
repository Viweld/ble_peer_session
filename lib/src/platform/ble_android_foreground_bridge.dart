import 'dart:async';

import 'package:flutter/services.dart';

import '../domain/exceptions/peer_exception.dart';

/// Native start/stop + task-removed callback for the Android FGS.
abstract interface class BleAndroidForegroundBridge {
  Stream<void> get taskRemoved;

  Future<void> start({
    required String title,
    required String body,
    String? smallIcon,
  });

  Future<void> stop();
}

final class MethodChannelBleAndroidForegroundBridge
    implements BleAndroidForegroundBridge {
  MethodChannelBleAndroidForegroundBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName) {
    _taskRemovedController = StreamController<void>.broadcast();
    _channel.setMethodCallHandler(_onMethodCall);
  }

  static const String _channelName = 'dev.viweld.ble_peer_session/foreground';

  final MethodChannel _channel;
  late final StreamController<void> _taskRemovedController;

  @override
  Stream<void> get taskRemoved => _taskRemovedController.stream;

  @override
  Future<void> start({
    required String title,
    required String body,
    String? smallIcon,
  }) async {
    try {
      await _channel.invokeMethod<void>('start', <String, Object?>{
        'title': title,
        'body': body,
        'smallIcon': smallIcon,
      });
    } on PlatformException catch (error, stackTrace) {
      throwPeer(PeerErrorCode.unexpected, cause: error, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException catch (error, stackTrace) {
      throwPeer(PeerErrorCode.unexpected, cause: error, stackTrace: stackTrace);
    }
  }

  Future<void> _onMethodCall(MethodCall call) async {
    if (call.method != 'onTaskRemoved') return;
    if (_taskRemovedController.isClosed) return;
    _taskRemovedController.add(null);
  }
}
