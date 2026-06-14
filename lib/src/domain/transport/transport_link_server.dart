import 'transport_link.dart';

/// Server-side BLE link: GATT peripheral and advertising (internal).
abstract interface class TransportLinkServer implements TransportLink {
  Future<void> startAdvertisingAs({required String deviceName});

  Future<void> stopAdvertising();
}
