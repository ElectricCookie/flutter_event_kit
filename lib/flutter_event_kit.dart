import 'src/messages.g.dart';
import 'src/date_time_converter.dart';
import 'package:flutter/services.dart';

export 'src/messages.g.dart';

class _EventKitFlutterCallbacks implements EventKitFlutterApi {
  @override
  void onCalendarAccessChanged(EventKitCalendarAuthorizationStatus status) {
    FlutterEventKit._onCalendarAccessChanged?.call(status);
  }

  @override
  void onEventsChanged() {
    FlutterEventKit._onEventsChanged?.call();
  }
}

class FlutterEventKit {
  static EventKitHostApi? _api;
  static bool _flutterApiSetup = false;
  static void Function()? _onEventsChanged;
  static void Function(EventKitCalendarAuthorizationStatus status)?
      _onCalendarAccessChanged;

  /// Initialize the plugin. This should be called before using any methods.
  static void initialize() {
    _api ??= EventKitHostApi(binaryMessenger: null);
    if (!_flutterApiSetup) {
      EventKitFlutterApi.setup(_EventKitFlutterCallbacks());
      _flutterApiSetup = true;
    }
  }

  /// Invoked when EventKit posts `EKEventStoreChanged`.
  static void setEventsChangedListener(void Function()? callback) {
    initialize();
    _onEventsChanged = callback;
  }

  /// Invoked after a calendar access request completes.
  static void setCalendarAccessChangedListener(
    void Function(EventKitCalendarAuthorizationStatus status)? callback,
  ) {
    initialize();
    _onCalendarAccessChanged = callback;
  }

  /// Get the EventKitHostApi instance, initializing if necessary
  static EventKitHostApi get _apiInstance {
    if (_api == null) {
      initialize();
    }
    return _api!;
  }

  // MARK: - Calendar Access

  /// Request access to calendar events
  static Future<bool> requestCalendarAccess() async {
    try {
      return await _apiInstance.requestCalendarAccess();
    } catch (e) {
      throw PlatformException(
        code: 'calendar_access_error',
        message: 'Failed to request calendar access: $e',
      );
    }
  }

  /// Get the current calendar authorization status
  static Future<EventKitCalendarAuthorizationStatus>
  getCalendarAuthorizationStatus() async {
    try {
      return await _apiInstance.getCalendarAuthorizationStatus();
    } catch (e) {
      throw PlatformException(
        code: 'calendar_status_error',
        message: 'Failed to get calendar authorization status: $e',
      );
    }
  }

  /// Request access to reminders
  static Future<bool> requestReminderAccess() async {
    try {
      return await _apiInstance.requestReminderAccess();
    } catch (e) {
      throw PlatformException(
        code: 'reminder_access_error',
        message: 'Failed to request reminder access: $e',
      );
    }
  }

  /// Get the current reminder authorization status
  static Future<EventKitCalendarAuthorizationStatus>
  getReminderAuthorizationStatus() async {
    try {
      return await _apiInstance.getReminderAuthorizationStatus();
    } catch (e) {
      throw PlatformException(
        code: 'reminder_status_error',
        message: 'Failed to get reminder authorization status: $e',
      );
    }
  }

  // MARK: - Calendars

  /// Get all available calendars
  static Future<List<EventKitCalendar>> getCalendars() async {
    final calendars = await _apiInstance.getCalendars();
    return calendars.whereType<EventKitCalendar>().toList();
  }

  /// Get a specific calendar by identifier
  static Future<EventKitCalendar?> getCalendar(String identifier) async {
    return await _apiInstance.getCalendar(identifier);
  }

  /// Get all available reminder calendars
  static Future<List<EventKitCalendar>> getReminderCalendars() async {
    final calendars = await _apiInstance.getReminderCalendars();
    return calendars.whereType<EventKitCalendar>().toList();
  }

  /// Get the default calendar for new reminders
  static Future<EventKitCalendar?> getDefaultReminderCalendar() async {
    return await _apiInstance.getDefaultReminderCalendar();
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
    final events = await _apiInstance.getEvents(
      pigeonStartDate,
      pigeonEndDate,
      calendarIdentifiers,
    );
    return events.whereType<EventKitEvent>().toList();
  }

  /// Get a specific event by identifier
  static Future<EventKitEvent?> getEvent(String identifier) async {
    return await _apiInstance.getEvent(identifier);
  }

  /// Get an event by [EKCalendarItem.calendarItemIdentifier].
  static Future<EventKitEvent?> getEventByCalendarItemIdentifier(
    String identifier,
  ) async {
    return await _apiInstance.getEventByCalendarItemIdentifier(identifier);
  }

  /// Events sharing a CalDAV UID ([calendarItemExternalIdentifier]).
  static Future<List<EventKitEvent>> getCalendarItemsWithExternalIdentifier(
    String externalIdentifier,
  ) async {
    final events = await _apiInstance.getCalendarItemsWithExternalIdentifier(
      externalIdentifier,
    );
    return events.whereType<EventKitEvent>().toList();
  }

  /// Save an event. When [event.identifier] / [event.eventIdentifier] is set,
  /// the existing EventKit event is mutated instead of duplicated.
  static Future<String> saveEvent(
    EventKitEvent event, {
    EventKitSpan span = EventKitSpan.thisEvent,
  }) async {
    return await _apiInstance.saveEvent(event, span);
  }

  /// Remove an event. Use [EventKitSpan.futureEvents] for this-and-future
  /// of a recurring series.
  static Future<bool> removeEvent(
    String identifier, {
    EventKitSpan span = EventKitSpan.thisEvent,
  }) async {
    return await _apiInstance.removeEvent(identifier, span);
  }

  /// Presents the system event view (iOS EventKitUI) for [eventIdentifier].
  ///
  /// Completes when the view is dismissed. Returns `false` on platforms that
  /// cannot present EventKitUI (macOS) or when the event cannot be found.
  static Future<bool> presentEventView(String eventIdentifier) async {
    try {
      return await _apiInstance.presentEventView(eventIdentifier);
    } catch (e) {
      throw PlatformException(
        code: 'present_event_view_error',
        message: 'Failed to present event view: $e',
      );
    }
  }

  // MARK: - Reminders

  /// Get reminders matching a predicate
  static Future<List<EventKitReminder>> getReminders({
    String? predicate,
  }) async {
    final reminders = await _apiInstance.getReminders(predicate);
    return reminders.whereType<EventKitReminder>().toList();
  }

  /// Save a reminder
  static Future<String> saveReminder(EventKitReminder reminder) async {
    return await _apiInstance.saveReminder(reminder);
  }

  /// Remove a reminder
  static Future<bool> removeReminder(String identifier) async {
    return await _apiInstance.removeReminder(identifier);
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
      startDateUnixMs: startDate.millisecondsSinceEpoch,
      endDateUnixMs: endDate.millisecondsSinceEpoch,
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

  // MARK: - Reminder Convenience Methods

  /// Get all reminders from a specific calendar/list
  static Future<List<EventKitReminder>> getRemindersInList(
    String calendarId,
  ) async {
    return await getReminders(predicate: calendarId);
  }

  /// Get all incomplete reminders from a specific calendar/list
  static Future<List<EventKitReminder>> getIncompleteRemindersInList(
    String calendarId,
  ) async {
    final reminders = await _apiInstance.getIncompleteReminders(
      [calendarId],
      null,
      null,
    );
    return reminders.whereType<EventKitReminder>().toList();
  }

  /// Get all incomplete reminders from the default reminder calendar
  static Future<List<EventKitReminder>>
  getIncompleteRemindersInDefaultList() async {
    final defaultCalendar = await getDefaultReminderCalendar();
    if (defaultCalendar == null) {
      return [];
    }
    return await getIncompleteRemindersInList(defaultCalendar.identifier);
  }

  /// Get all completed reminders from a specific calendar/list
  static Future<List<EventKitReminder>> getCompletedRemindersInList(
    String calendarId,
  ) async {
    final reminders = await _apiInstance.getCompletedReminders(
      [calendarId],
      null,
      null,
    );
    return reminders.whereType<EventKitReminder>().toList();
  }

  /// Get all completed reminders from the default reminder calendar
  static Future<List<EventKitReminder>>
  getCompletedRemindersInDefaultList() async {
    final defaultCalendar = await getDefaultReminderCalendar();
    if (defaultCalendar == null) {
      return [];
    }
    return await getCompletedRemindersInList(defaultCalendar.identifier);
  }

  /// Get all incomplete reminders from all calendars
  static Future<List<EventKitReminder>> getAllIncompleteReminders() async {
    final reminders = await _apiInstance.getIncompleteReminders(
      null,
      null,
      null,
    );
    return reminders.whereType<EventKitReminder>().toList();
  }

  /// Get all completed reminders from all calendars
  static Future<List<EventKitReminder>> getAllCompletedReminders() async {
    final reminders = await _apiInstance.getCompletedReminders(
      null,
      null,
      null,
    );
    return reminders.whereType<EventKitReminder>().toList();
  }

  /// Get incomplete reminders with due dates in a specific date range
  static Future<List<EventKitReminder>> getIncompleteRemindersInDateRange(
    DateTime startDate,
    DateTime endDate, {
    List<String>? calendarIdentifiers,
  }) async {
    final pigeonStartDate = DateTimeConverter.toPigeon(startDate);
    final pigeonEndDate = DateTimeConverter.toPigeon(endDate);
    final reminders = await _apiInstance.getIncompleteReminders(
      calendarIdentifiers,
      pigeonStartDate,
      pigeonEndDate,
    );
    return reminders.whereType<EventKitReminder>().toList();
  }

  /// Get completed reminders with completion dates in a specific date range
  static Future<List<EventKitReminder>> getCompletedRemindersInDateRange(
    DateTime startDate,
    DateTime endDate, {
    List<String>? calendarIdentifiers,
  }) async {
    final pigeonStartDate = DateTimeConverter.toPigeon(startDate);
    final pigeonEndDate = DateTimeConverter.toPigeon(endDate);
    final reminders = await _apiInstance.getCompletedReminders(
      calendarIdentifiers,
      pigeonStartDate,
      pigeonEndDate,
    );
    return reminders.whereType<EventKitReminder>().toList();
  }

  /// Get overdue reminders (incomplete reminders with a due date in the past) from a specific calendar/list
  static Future<List<EventKitReminder>> getOverdueRemindersInList(
    String calendarId,
  ) async {
    final now = DateTime.now();
    final pastDate = DateTime(1970, 1, 1); // A date far in the past
    return await getIncompleteRemindersInDateRange(
      pastDate,
      now,
      calendarIdentifiers: [calendarId],
    );
  }

  /// Get overdue reminders from the default reminder calendar
  static Future<List<EventKitReminder>>
  getOverdueRemindersInDefaultList() async {
    final defaultCalendar = await getDefaultReminderCalendar();
    if (defaultCalendar == null) {
      return [];
    }
    return await getOverdueRemindersInList(defaultCalendar.identifier);
  }

  /// Get all overdue reminders from all calendars
  static Future<List<EventKitReminder>> getAllOverdueReminders() async {
    final now = DateTime.now();
    final pastDate = DateTime(1970, 1, 1); // A date far in the past
    return await getIncompleteRemindersInDateRange(pastDate, now);
  }

  /// Get reminders due today from a specific calendar/list
  static Future<List<EventKitReminder>> getRemindersDueTodayInList(
    String calendarId,
  ) async {
    final today = DateTime.now();
    final startOfDay = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(milliseconds: 1));
    final endOfDay = DateTime(
      today.year,
      today.month,
      today.day,
    ).add(const Duration(days: 1));
    return await getIncompleteRemindersInDateRange(
      startOfDay,
      endOfDay,
      calendarIdentifiers: [calendarId],
    );
  }

  /// Get reminders due today from the default reminder calendar
  static Future<List<EventKitReminder>>
  getRemindersDueTodayInDefaultList() async {
    final defaultCalendar = await getDefaultReminderCalendar();
    if (defaultCalendar == null) {
      return [];
    }
    return await getRemindersDueTodayInList(defaultCalendar.identifier);
  }
}
