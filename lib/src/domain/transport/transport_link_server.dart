import 'transport_link.dart';

/// Серверный BLE-канал: advertising.
abstract interface class TransportLinkServer implements TransportLink {
  Future<void> startAdvertisingAs({required String deviceName});

  Future<void> stopAdvertising();
}
