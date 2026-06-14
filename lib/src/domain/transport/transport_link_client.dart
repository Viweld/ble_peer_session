import '../models/device.dart';
import 'transport_link.dart';

/// Client-side BLE link: scan and connect to peripherals (internal).
abstract interface class TransportLinkClient implements TransportLink {
  Stream<List<Device>> get discoveredDevicesStream;

  Future<void> startDiscovery();

  Future<void> stopDiscovery();

  Future<void> refreshDiscovery();

  Future<void> connectToDevice(Device device);
}
