import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../domain/models/peer_adapter_status.dart';
import '../../domain/mappers/peer_adapter_mapper.dart';

/// Observes the system Bluetooth adapter and exposes [PeerAdapterStatus].
abstract interface class PeerAdapterService {
  Stream<PeerAdapterStatus> get statusStream;

  PeerAdapterStatus get currentStatus;
}

final class PeerAdapterServiceImpl implements PeerAdapterService {
  @override
  Stream<PeerAdapterStatus> get statusStream =>
      FlutterBluePlus.adapterState.map(PeerAdapterMapper.fromFlutterBluePlus);

  @override
  PeerAdapterStatus get currentStatus =>
      PeerAdapterMapper.fromFlutterBluePlus(FlutterBluePlus.adapterStateNow);
}
