# Flutter EventKit Plugin

A Flutter plugin that provides type-safe access to the EventKit API for both iOS and macOS platforms. This plugin uses Pigeon for code generation and maintains a shared native implementation between platforms.

## Installation

Add the plugin to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_event_kit: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Permissions

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSCalendarsUsageDescription</key>
<string>This app needs access to calendars to manage events and reminders.</string>
```

Add to `ios/Runner/Runner.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.personal-information.calendars</key>
    <true/>
</dict>
</plist>
```

### macOS

Add to `macos/Runner/Info.plist`:

```xml
<key>NSCalendarsUsageDescription</key>
<string>This app needs access to calendars to manage events and reminders.</string>
```

Add to `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    ....
    <key>com.apple.security.personal-information.calendars</key>
    <true/>
</dict>
</plist>
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

## Requirements

- **iOS**: 12.0+
- **macOS**: 10.15+
- **Flutter**: 3.3.0+
- **Dart**: 3.9.0+

## Development

### Code Generation with Pigeon

This plugin uses [Pigeon](https://pub.dev/packages/pigeon) for type-safe code generation between Dart and Swift. The Pigeon definitions are located in `pigeons/messages.dart`.

#### Regenerating Code

To regenerate the Pigeon code after making changes to `pigeons/messages.dart`:

```bash
# Run the build script
./tool/pigeon.sh

# Or manually
dart run pigeon --input pigeons/messages.dart
```

This generates:

- **Dart side**: `lib/src/messages.g.dart`
- **Swift side**: `shared/Classes/Shared/Messages.g.swift`

#### Adding New Features

1. **Update Pigeon definitions** in `pigeons/messages.dart`
2. **Implement in shared service** in `shared/Classes/Shared/EventKitService.swift`
3. **Add conversion methods** in both platform plugins
4. **Update Dart API** in `lib/flutter_event_kit.dart`
5. **Regenerate code** using Pigeon

### Swift Code Synchronization

The plugin maintains a shared Swift implementation between iOS and macOS platforms. Use the sync script to ensure both platforms use the same code:

```bash
# Sync shared Swift code to iOS and macOS directories
./tool/sync_swift_code.sh
```

This script:

- Copies `FlutterEventKitPlugin.swift` to both platform directories
- Syncs all shared files from `shared/Classes/Shared/` to both platforms
- Ensures consistency between iOS and macOS implementations

### Architecture

#### Shared Native Implementation

Pigeon generates type-safe code for:

- **Dart side**: `lib/src/messages.g.dart`
- **Swift side**: `ios/Classes/Shared/Messages.g.swift`

This eliminates the need for manual method channel implementation and provides compile-time type safety.

#### File Structure

```
flutter_event_kit/
├── lib/
│   ├── flutter_event_kit.dart          # Main plugin API
│   ├── flutter_event_kit_platform_interface.dart
│   └── src/
│       └── messages.g.dart             # Pigeon-generated Dart code
├── shared/Classes/                     # Shared Swift implementation
│   ├── FlutterEventKitPlugin.swift
│   └── Shared/
│       ├── EventKitService.swift       # Shared EventKit logic
│       └── Messages.g.swift            # Pigeon-generated Swift code
├── ios/Classes/                        # iOS-specific files
│   ├── FlutterEventKitPlugin.swift     # iOS plugin implementation
│   └── Shared/                         # Synced from shared/
├── macos/Classes/                      # macOS-specific files
│   ├── FlutterEventKitPlugin.swift     # macOS plugin implementation
│   └── Shared/                         # Synced from shared/
├── pigeons/
│   └── messages.dart                    # Pigeon message definitions
└── tool/
    ├── pigeon.sh                       # Pigeon code generation script
    └── sync_swift_code.sh              # Swift code sync script
```

### Platform-Specific Code

When platform-specific code is needed, use conditional compilation:

```swift
#if os(iOS)
// iOS-specific code
#elseif os(macOS)
// macOS-specific code
#endif
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
