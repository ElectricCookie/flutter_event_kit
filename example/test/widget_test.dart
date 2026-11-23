import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_event_kit_example/main.dart';

void main() {
  testWidgets('shows the EventKit example', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('EventKit Example'), findsOneWidget);
  });
}
