import 'src/messages.g.dart';
import 'src/date_time_converter.dart';

export 'src/messages.g.dart';

class FlutterEventKit {
  static final EventKitHostApi _api = EventKitHostApi();

  // MARK: - Calendar Access

  /// Request access to calendar events
  static Future<bool> requestCalendarAccess() async {
    return await _api.requestCalendarAccess();
  }

  /// Get the current calendar authorization status
  static Future<EventKitCalendarAuthorizationStatus>
  getCalendarAuthorizationStatus() async {
    return await _api.getCalendarAuthorizationStatus();
  }

  // MARK: - Calendars

  /// Get all available calendars
  static Future<List<EventKitCalendar>> getCalendars() async {
    final calendars = await _api.getCalendars();
    return calendars.whereType<EventKitCalendar>().toList();
  }

  /// Get a specific calendar by identifier
  static Future<EventKitCalendar?> getCalendar(String identifier) async {
    return await _api.getCalendar(identifier);
  }

  // MARK: - Events

  /// Get events within a date range
  static Future<List<EventKitEvent>> getEvents(
    DateTime startDate,
    DateTime endDate, {
    List<String>? calendarIdentifiers,
  }) async {
    final pigeonStartDate = DateTimeConverter.toPigeon(startDate);
    final pigeonEndDate = DateTimeConverter.toPigeon(endDate);
    final events = await _api.getEvents(
      pigeonStartDate,
      pigeonEndDate,
      calendarIdentifiers,
    );
    return events.whereType<EventKitEvent>().toList();
  }

  /// Get a specific event by identifier
  static Future<EventKitEvent?> getEvent(String identifier) async {
    return await _api.getEvent(identifier);
  }

  /// Save an event to the calendar
  static Future<String> saveEvent(EventKitEvent event) async {
    return await _api.saveEvent(event);
  }

  /// Remove an event from the calendar
  static Future<bool> removeEvent(String identifier) async {
    return await _api.removeEvent(identifier);
  }

  // MARK: - Reminders

  /// Get reminders matching a predicate
  static Future<List<EventKitReminder>> getReminders({
    String? predicate,
  }) async {
    final reminders = await _api.getReminders(predicate);
    return reminders.whereType<EventKitReminder>().toList();
  }

  /// Save a reminder
  static Future<String> saveReminder(EventKitReminder reminder) async {
    return await _api.saveReminder(reminder);
  }

  /// Remove a reminder
  static Future<bool> removeReminder(String identifier) async {
    return await _api.removeReminder(identifier);
  }

  // MARK: - Convenience Methods

  /// Create a new event with basic properties
  static EventKitEvent createEvent({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
    String? location,
    bool isAllDay = false,
    String? calendarId,
  }) {
    return EventKitEvent(
      title: title,
      startDate: DateTimeConverter.toPigeon(startDate),
      endDate: DateTimeConverter.toPigeon(endDate),
      isAllDay: isAllDay,
      availability: EventKitEventAvailability.busy,
      status: EventKitEventStatus.none,
      notes: notes,
      location: location,
      calendarId: calendarId,
    );
  }

  /// Create a new reminder with basic properties
  static EventKitReminder createReminder({
    required String title,
    DateTime? dueDate,
    String? notes,
    String? calendarId,
  }) {
    return EventKitReminder(
      title: title,
      isCompleted: false,
      notes: notes,
      dueDate: DateTimeConverter.toPigeonNullable(dueDate),
      calendarId: calendarId,
    );
  }
}
