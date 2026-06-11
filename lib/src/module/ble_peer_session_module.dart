import '../config/ble_peer_config.dart';
import '../data/ble/facade/ble_transport_facade_impl.dart';
import '../data/ble/link/ble_link_client_impl.dart';
import '../data/ble/link/ble_link_server_impl.dart';
import '../data/ble/messenger/ble_messenger_impl.dart';
import '../data/ble/session/ble_session_client_impl.dart';
import '../data/ble/session/ble_session_server_impl.dart';
import '../data/services/bluetooth_permissions_service_impl.dart';
import '../data/services/bluetooth_state_service_impl.dart';
import '../domain/logger/logger.dart';
import '../domain/services/bluetooth_permissions_service.dart';
import '../domain/services/bluetooth_state_service.dart';
import '../domain/transport/transport_facade.dart';
import '../domain/transport/transport_session_client.dart';
import '../domain/transport/transport_session_server.dart';

/// Фабрика BLE P2P-транспорта.
final class BlePeerSessionModule {
  const BlePeerSessionModule._({
    required this.transportFacade,
    required this.transportSessionClient,
    required this.transportSessionServer,
    required this.bluetoothStateService,
    required this.bluetoothPermissionsService,
  });

  final TransportFacade transportFacade;
  final TransportSessionClient transportSessionClient;
  final TransportSessionServer transportSessionServer;
  final BluetoothStateService bluetoothStateService;
  final BluetoothPermissionsService bluetoothPermissionsService;

  factory BlePeerSessionModule.create({
    required BlePeerConfig config,
    required Logger logger,
  }) {
    final linkClient = BleLinkClientImpl(logger: logger, config: config);
    final linkServer = BleLinkServerImpl(logger: logger, config: config);
    final messengerClient = BleMessengerImpl(connector: linkClient, logger: logger);
    final messengerServer = BleMessengerImpl(connector: linkServer, logger: logger);
    final sessionClient = BleSessionClientImpl(
      link: linkClient,
      messenger: messengerClient,
    );
    final sessionServer = BleSessionServerImpl(
      link: linkServer,
      messenger: messengerServer,
    );
    final facade = BleTransportFacadeImpl(
      transportSessionClient: sessionClient,
      transportSessionServer: sessionServer,
    );

    return BlePeerSessionModule._(
      transportFacade: facade,
      transportSessionClient: sessionClient,
      transportSessionServer: sessionServer,
      bluetoothStateService: BluetoothStateServiceImpl(),
      bluetoothPermissionsService: BluetoothPermissionsServiceImpl(),
    );
  }

  Future<void> dispose() => transportFacade.dispose();
}
