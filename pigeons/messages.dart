import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    dartOptions: DartOptions(copyrightHeader: []),
    swiftOut: 'ios/Classes/Shared/Messages.g.swift',
    swiftOptions: SwiftOptions(),
  ),
)
@HostApi()
abstract class EventKitHostApi {
  @async
  bool requestCalendarAccess();

  @async
  EventKitCalendarAuthorizationStatus getCalendarAuthorizationStatus();

  @async
  List<EventKitCalendar> getCalendars();

  @async
  EventKitCalendar? getCalendar(String identifier);

  @async
  List<EventKitEvent> getEvents(
    EventKitDateTime startDate,
    EventKitDateTime endDate,
    List<String>? calendarIdentifiers,
  );

  @async
  EventKitEvent? getEvent(String identifier);

  @async
  String saveEvent(EventKitEvent event);

  @async
  bool removeEvent(String identifier);

  @async
  List<EventKitReminder> getReminders(String? predicate);

  @async
  String saveReminder(EventKitReminder reminder);

  @async
  bool removeReminder(String identifier);
}

@FlutterApi()
abstract class EventKitFlutterApi {
  void onCalendarAccessChanged(EventKitCalendarAuthorizationStatus status);
  void onEventsChanged();
}

// MARK: - Data Models

@HostApi()
abstract class CalendarHostApi {
  @async
  List<EventKitCalendar> getCalendars();
}

@HostApi()
abstract class EventHostApi {
  @async
  List<EventKitEvent> getEvents(
    EventKitDateTime startDate,
    EventKitDateTime endDate,
    List<String>? calendarIdentifiers,
  );
  @async
  EventKitEvent? getEvent(String identifier);
  @async
  String saveEvent(EventKitEvent event);
  @async
  bool removeEvent(String identifier);
}

@HostApi()
abstract class ReminderHostApi {
  @async
  List<EventKitReminder> getReminders(String? predicate);
  @async
  String saveReminder(EventKitReminder reminder);
  @async
  bool removeReminder(String identifier);
}

// MARK: - Enums

enum EventKitCalendarAuthorizationStatus {
  notDetermined,
  restricted,
  denied,
  authorized,
}

enum EventKitEventAvailability {
  notSupported,
  busy,
  free,
  tentative,
  unavailable,
}

enum EventKitEventStatus { none, confirmed, tentative, canceled }

enum EventKitRecurrenceFrequency { daily, weekly, monthly, yearly }

// MARK: - Data Classes

class EventKitDateTime {
  int year;
  int month;
  int day;
  int hour;
  int minute;
  int second;
  int millisecond;

  EventKitDateTime({
    required this.year,
    required this.month,
    required this.day,
    this.hour = 0,
    this.minute = 0,
    this.second = 0,
    this.millisecond = 0,
  });
}

class EventKitCalendar {
  String identifier;
  String title;
  String? source;
  String? color;
  bool isEditable;
  bool isSubscribed;
  String? externalId;

  EventKitCalendar({
    required this.identifier,
    required this.title,
    this.source,
    this.color,
    required this.isEditable,
    required this.isSubscribed,
    this.externalId,
  });
}

class EventKitEvent {
  String? identifier;
  String title;
  String? notes;
  EventKitDateTime startDate;
  EventKitDateTime endDate;
  bool isAllDay;
  String? location;
  String? url;
  EventKitEventAvailability availability;
  EventKitEventStatus status;
  String? calendarId;
  List<String?>? attendeeEmails;
  EventKitRecurrenceRule? recurrenceRule;

  EventKitEvent({
    this.identifier,
    required this.title,
    this.notes,
    required this.startDate,
    required this.endDate,
    this.isAllDay = false,
    this.location,
    this.url,
    this.availability = EventKitEventAvailability.busy,
    this.status = EventKitEventStatus.none,
    this.calendarId,
    this.attendeeEmails,
    this.recurrenceRule,
  });
}

class EventKitReminder {
  String? identifier;
  String title;
  String? notes;
  EventKitDateTime? dueDate;
  EventKitDateTime? completionDate;
  bool isCompleted;
  String? calendarId;
  int? priority;

  EventKitReminder({
    this.identifier,
    required this.title,
    this.notes,
    this.dueDate,
    this.completionDate,
    this.isCompleted = false,
    this.calendarId,
    this.priority,
  });
}

class EventKitRecurrenceRule {
  EventKitRecurrenceFrequency frequency;
  int interval;
  EventKitDateTime? endDate;
  int? occurrenceCount;
  List<int?>? daysOfTheWeek;
  List<int?>? daysOfTheMonth;
  List<int?>? monthsOfTheYear;

  EventKitRecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.endDate,
    this.occurrenceCount,
    this.daysOfTheWeek,
    this.daysOfTheMonth,
    this.monthsOfTheYear,
  });
}
