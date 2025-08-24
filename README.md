# Flutter EventKit Plugin

A Flutter plugin that provides type-safe access to the EventKit API for both iOS and macOS platforms. This plugin uses Pigeon for code generation and maintains a shared native implementation between platforms.

## Features

- **Cross-platform support**: iOS and macOS
- **Type-safe communication**: Uses Pigeon for generated code
- **Shared native implementation**: Single Swift codebase for both platforms
- **Full EventKit access**: Calendars, events, reminders, and more
- **Modern async/await API**: Built with Flutter's latest async patterns

## Architecture

### Shared Native Implementation

The plugin uses a shared `EventKitService` class that contains all the EventKit logic. This service is imported by both the iOS and macOS plugin classes, ensuring:

- **Code consistency** between platforms
- **Easier maintenance** with a single source of truth
- **Platform-specific handling** where needed through conditional compilation

### Pigeon Integration

Pigeon generates type-safe code for:

- **Dart side**: `lib/src/messages.g.dart`
- **Swift side**: `ios/Classes/Shared/Messages.g.swift`

This eliminates the need for manual method channel implementation and provides compile-time type safety.

### File Structure

```
flutter_event_kit/
├── lib/
│   ├── flutter_event_kit.dart          # Main plugin API
│   ├── flutter_event_kit_platform_interface.dart
│   └── src/
│       └── messages.g.dart             # Pigeon-generated Dart code
├── ios/Classes/
│   ├── FlutterEventKitPlugin.swift     # iOS plugin implementation
│   └── Shared/
│       ├── EventKitService.swift       # Shared EventKit logic
│       └── Messages.g.swift            # Pigeon-generated Swift code
├── macos/Classes/
│   ├── FlutterEventKitPlugin.swift     # macOS plugin implementation
│   └── Shared/
│       ├── EventKitService.swift       # Shared EventKit logic
│       └── Messages.g.swift            # Pigeon-generated Swift code
└── pigeons/
    └── messages.dart                    # Pigeon message definitions
```

## Installation

Add the plugin to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_event_kit: ^0.0.1
```

## Usage

### Basic Setup

```dart
import 'package:flutter_event_kit/flutter_event_kit.dart';

// Request calendar access
bool hasAccess = await FlutterEventKit.requestCalendarAccess();

// Check authorization status
CalendarAuthorizationStatus status = await FlutterEventKit.getCalendarAuthorizationStatus();
```

### Working with Calendars

```dart
// Get all calendars
List<Calendar> calendars = await FlutterEventKit.getCalendars();

// Get specific calendar
Calendar? calendar = await FlutterEventKit.getCalendar('calendar_id');
```

### Working with Events

```dart
// Create a new event
Event event = FlutterEventKit.createEvent(
  title: 'Meeting',
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(hours: 1)),
  location: 'Conference Room A',
);

// Save the event
String eventId = await FlutterEventKit.saveEvent(event);

// Get events in a date range
List<Event> events = await FlutterEventKit.getEvents(
  DateTime.now(),
  DateTime.now().add(Duration(days: 7)),
);

// Remove an event
bool removed = await FlutterEventKit.removeEvent(eventId);
```

### Working with Reminders

```dart
// Create a reminder
Reminder reminder = FlutterEventKit.createReminder(
  title: 'Buy groceries',
  dueDate: DateTime.now().add(Duration(days: 1)),
);

// Save the reminder
String reminderId = await FlutterEventKit.saveReminder(reminder);

// Get all reminders
List<Reminder> reminders = await FlutterEventKit.getReminders();
```

## Development

### Code Generation

To regenerate the Pigeon code after making changes to `pigeons/messages.dart`:

```bash
# Run the build script
./tool/pigeon.sh

# Or manually
dart run pigeon --input pigeons/messages.dart
```

### Adding New Features

1. **Update Pigeon definitions** in `pigeons/messages.dart`
2. **Implement in shared service** in `ios/Classes/Shared/EventKitService.swift`
3. **Add conversion methods** in both platform plugins
4. **Update Dart API** in `lib/flutter_event_kit.dart`
5. **Regenerate code** using Pigeon

### Platform-Specific Code

When platform-specific code is needed, use conditional compilation:

```swift
#if os(iOS)
// iOS-specific code
#elseif os(macOS)
// macOS-specific code
#endif
```

## Requirements

- **iOS**: 12.0+
- **macOS**: 10.15+
- **Flutter**: 3.3.0+
- **Dart**: 3.9.0+

## Permissions

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSCalendarsUsageDescription</key>
<string>This app needs access to calendars to manage events and reminders.</string>
```

### macOS

Add to `macos/Runner/Info.plist`:

```xml
<key>NSCalendarsUsageDescription</key>
<string>This app needs access to calendars to manage events and reminders.</string>
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
