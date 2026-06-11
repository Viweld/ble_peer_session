import '../models/device.dart';
import '../models/peer_endpoint.dart';
import 'transport_session.dart';

/// Клиентская транспортная сессия.
abstract interface class TransportSessionClient implements TransportSession {
  Stream<List<Device>> get discoveredDevicesStream;

  Future<void> startDiscovery({required PeerEndpoint localPeer});

  Future<void> stopDiscovery();

  Future<void> refreshDiscovery();

  Future<void> connectToDevice(Device device);
}
