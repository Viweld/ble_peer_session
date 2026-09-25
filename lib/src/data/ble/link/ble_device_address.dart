/// Recovers a Bluetooth MAC from a discovery id.
///
/// `bluetooth_low_energy` stores the address as `UUID.fromAddress`, which is
/// `00000000-0000-0000-0000-` plus the 12 hex digits of the MAC.
String? bluetoothAddressFromDeviceId(String deviceId) {
  final RegExp mac = RegExp(r'^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$');
  if (mac.hasMatch(deviceId)) {
    return deviceId.toUpperCase();
  }

  final RegExp node = RegExp(r'^00000000-0000-0000-0000-([0-9a-fA-F]{12})$');
  final Match? match = node.firstMatch(deviceId);
  if (match == null) return null;

  final String digits = match.group(1)!;
  final List<String> bytes = <String>[
    for (int index = 0; index < digits.length; index += 2)
      digits.substring(index, index + 2),
  ];
  return bytes.join(':').toUpperCase();
}
