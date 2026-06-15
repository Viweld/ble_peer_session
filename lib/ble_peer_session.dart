/// Offline 1:1 peer sessions over BLE for Flutter.
///
/// Host/client model with invitation handshake and bidirectional messaging.
/// See [Peer] for the main entry point.
library;

export 'src/config/ble_peer_config.dart';
export 'src/config/ble_peer_uuid_generator.dart';
export 'src/domain/exceptions/peer_exception.dart';
export 'src/domain/logger/logger.dart';
export 'src/domain/logger/silent_logger.dart';
export 'src/domain/models/device.dart';
export 'src/domain/models/peer_adapter_status.dart';
export 'src/domain/models/peer_connection_phase.dart';
export 'src/domain/models/peer_disconnect_info.dart';
export 'src/domain/models/peer_disconnect_reason.dart';
export 'src/domain/models/peer_endpoint.dart';
export 'src/domain/models/peer_identity.dart';
export 'src/domain/models/peer_message.dart';
export 'src/domain/models/peer_nearby.dart';
export 'src/domain/models/peer_user.dart';
export 'src/domain/services/bluetooth_permissions_service.dart';
export 'src/peer/peer.dart';
export 'src/peer/peer_client.dart';
export 'src/peer/peer_host.dart';
export 'src/peer/peer_session_messaging.dart';
