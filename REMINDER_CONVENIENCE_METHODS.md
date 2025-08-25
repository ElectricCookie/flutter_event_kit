# Reminder Convenience Methods

The `FlutterEventKit` class now includes several convenience methods for retrieving reminders with common predicates. These methods use native EventKit predicates for efficient server-side filtering.

## Available Methods

### Basic List Operations

- **`getRemindersInList(String calendarId)`** - Get all reminders from a specific calendar/list
- **`getIncompleteRemindersInList(String calendarId)`** - Get all incomplete reminders from a specific calendar/list
- **`getCompletedRemindersInList(String calendarId)`** - Get all completed reminders from a specific calendar/list

### Default List Operations

- **`getIncompleteRemindersInDefaultList()`** - Get all incomplete reminders from the default reminder calendar
- **`getCompletedRemindersInDefaultList()`** - Get all completed reminders from the default reminder calendar
- **`getOverdueRemindersInDefaultList()`** - Get overdue reminders from the default reminder calendar
- **`getRemindersDueTodayInDefaultList()`** - Get reminders due today from the default reminder calendar

### Global Operations

- **`getAllIncompleteReminders()`** - Get all incomplete reminders from all calendars
- **`getAllCompletedReminders()`** - Get all completed reminders from all calendars
- **`getAllOverdueReminders()`** - Get all overdue reminders from all calendars

### Date Range Operations

- **`getIncompleteRemindersInDateRange(DateTime startDate, DateTime endDate, {List<String>? calendarIdentifiers})`** - Get incomplete reminders with due dates in a specific date range
- **`getCompletedRemindersInDateRange(DateTime startDate, DateTime endDate, {List<String>? calendarIdentifiers})`** - Get completed reminders with completion dates in a specific date range

### Due Date Operations

- **`getOverdueRemindersInList(String calendarId)`** - Get overdue reminders from a specific calendar/list
- **`getRemindersDueTodayInList(String calendarId)`** - Get reminders due today from a specific calendar/list

## Usage Examples

```dart
// Get all incomplete reminders from the default list
final incompleteReminders = await FlutterEventKit.getIncompleteRemindersInDefaultList();

// Get all overdue reminders from all calendars
final overdueReminders = await FlutterEventKit.getAllOverdueReminders();

// Get reminders due today from a specific calendar
final todayReminders = await FlutterEventKit.getRemindersDueTodayInList('calendar_identifier');

// Get incomplete reminders in a date range
final dateRangeReminders = await FlutterEventKit.getIncompleteRemindersInDateRange(
  DateTime.now(),
  DateTime.now().add(Duration(days: 7)),
  calendarIdentifiers: ['calendar_id'],
);

// Get completed reminders in a date range
final completedReminders = await FlutterEventKit.getCompletedRemindersInDateRange(
  DateTime.now().subtract(Duration(days: 30)),
  DateTime.now(),
);
```

## Notes

- **Overdue reminders** are defined as incomplete reminders with a due date in the past
- **Reminders due today** are reminders with a due date falling within the current day
- **Default list** refers to the user's default reminder calendar
- All methods return `Future<List<EventKitReminder>>` and handle errors gracefully
- These methods use native EventKit predicates for efficient server-side filtering:
  - `predicateForIncompleteReminders(withDueDateStarting:ending:calendars:)`
  - `predicateForCompletedReminders(withCompletionDateStarting:ending:calendars:)`
- Date range operations allow for precise filtering of reminders based on due dates or completion dates
