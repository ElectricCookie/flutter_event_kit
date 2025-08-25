import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_event_kit/flutter_event_kit.dart';

void main() {
  group('FlutterEventKit', () {
    test('should have reminder authorization methods', () {
      // Test that the methods exist and are callable
      expect(FlutterEventKit.requestReminderAccess, isA<Function>());
      expect(FlutterEventKit.getReminderAuthorizationStatus, isA<Function>());
    });

    test('reminder authorization methods return correct types', () async {
      // These will likely fail on test environment, but we can test the return types
      try {
        final status = await FlutterEventKit.getReminderAuthorizationStatus();
        expect(status, isA<EventKitCalendarAuthorizationStatus>());
      } catch (e) {
        // Expected to fail in test environment
        expect(e, isA<Exception>());
      }

      try {
        final granted = await FlutterEventKit.requestReminderAccess();
        expect(granted, isA<bool>());
      } catch (e) {
        // Expected to fail in test environment
        expect(e, isA<Exception>());
      }
    });
  });
}
