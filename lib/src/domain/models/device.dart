import 'package:meta/meta.dart';

@immutable
final class Device {
  const Device({
    required this.id,
    required this.name,
    required this.isOurApp,
  });

  final String id;
  final String name;
  final bool isOurApp;
}
