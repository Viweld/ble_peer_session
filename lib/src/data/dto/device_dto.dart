import '../../domain/models/device.dart';

final class DeviceDto {
  const DeviceDto({
    required this.id,
    required this.name,
    required this.isOurApp,
  });

  final String id;
  final String name;
  final bool isOurApp;

  factory DeviceDto.fromJson(Map<String, dynamic> json) => DeviceDto(
    id: json['id'] as String,
    name: json['name'] as String,
    isOurApp: json['is_our_app'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'is_our_app': isOurApp,
  };

  Device toDomain() => Device(id: id, name: name, isOurApp: isOurApp);

  static DeviceDto fromDomain(Device device) =>
      DeviceDto(id: device.id, name: device.name, isOurApp: device.isOurApp);
}
