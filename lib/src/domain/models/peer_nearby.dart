import 'package:meta/meta.dart';

import 'device.dart';

/// A nearby host discovered while scanning (friendly name for [Device]).
@immutable
final class PeerNearby {
  const PeerNearby._(this._device);

  final Device _device;

  String get id => _device.id;

  String get displayName => _device.name;

  bool get isSameApp => _device.isOurApp;

  /// Internal transport handle. Prefer [id] and [displayName] in application code.
  Device get device => _device;

  factory PeerNearby.fromDevice(Device device) => PeerNearby._(device);
}
