import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_chat/main.dart';

void main() {
  testWidgets('role picker shows host and client actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MinimalChatApp());

    expect(find.text('BLE Minimal Chat'), findsOneWidget);
    expect(find.text('Host — wait for friend'), findsOneWidget);
    expect(find.text('Client — find host'), findsOneWidget);
  });
}
