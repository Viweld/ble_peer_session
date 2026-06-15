import 'dart:convert';
import 'dart:typed_data';

import 'ble_peer_config.dart';

/// Derives stable BLE UUIDs from [appName] so every install of the same app can find each other.
abstract final class BlePeerUuidGenerator {
  static BlePeerConfig configFor(
    String appName, {
    String deviceNamePrefix = '',
  }) {
    return BlePeerConfig(
      appName: appName,
      serviceUuid: uuidFor(appName: appName, kind: 'service'),
      characteristicUuid: uuidFor(appName: appName, kind: 'characteristic'),
      deviceNamePrefix: deviceNamePrefix,
    );
  }

  static String uuidFor({required String appName, required String kind}) {
    final List<int> seed = utf8.encode('ble_peer_session.v1:$kind:$appName');
    final Uint8List bytes = _hashToUuidBytes(seed);
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    return _formatUuid(bytes);
  }

  static Uint8List _hashToUuidBytes(List<int> seed) {
    var hash1 = 0x811c9dc5;
    var hash2 = 0x01000193;
    var hash3 = 0x85ebca6b;
    var hash4 = 0xc2b2ae35;

    for (final int byte in seed) {
      hash1 = (hash1 ^ byte) * 0x01000193;
      hash2 = (hash2 ^ (byte + 17)) * 0x01000193;
      hash3 = (hash3 ^ (byte + 31)) * 0x01000193;
      hash4 = (hash4 ^ (byte + 47)) * 0x01000193;
    }

    final ByteData data = ByteData(16);
    data.setUint32(0, hash1);
    data.setUint32(4, hash2);
    data.setUint32(8, hash3);
    data.setUint32(12, hash4);
    return data.buffer.asUint8List();
  }

  static String _formatUuid(Uint8List bytes) {
    String hex(int index) => bytes[index].toRadixString(16).padLeft(2, '0');

    return '${hex(0)}${hex(1)}${hex(2)}${hex(3)}-'
        '${hex(4)}${hex(5)}-'
        '${hex(6)}${hex(7)}-'
        '${hex(8)}${hex(9)}-'
        '${hex(10)}${hex(11)}${hex(12)}${hex(13)}${hex(14)}${hex(15)}';
  }
}
