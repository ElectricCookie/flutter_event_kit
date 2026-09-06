import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    dartOptions: DartOptions(copyrightHeader: []),
    swiftOut: 'shared/Classes/Shared/Messages.g.swift',
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
  bool requestReminderAccess();

  @async
  EventKitCalendarAuthorizationStatus getReminderAuthorizationStatus();

  @async
  List<EventKitCalendar> getCalendars();

  @async
  EventKitCalendar? getCalendar(String identifier);

  @async
  List<EventKitCalendar> getReminderCalendars();

  @async
  EventKitCalendar? getDefaultReminderCalendar();

  @async
  List<EventKitEvent> getEvents(
    EventKitDateTime startDate,
    EventKitDateTime endDate,
    List<String>? calendarIdentifiers,
  );

  @async
  EventKitEvent? getEvent(String identifier);

  @async
  EventKitEvent? getEventByCalendarItemIdentifier(String identifier);

  @async
  List<EventKitEvent> getCalendarItemsWithExternalIdentifier(
    String externalIdentifier,
  );

  @async
  String saveEvent(EventKitEvent event, EventKitSpan span);

  @async
  bool removeEvent(String identifier, EventKitSpan span);

  /// Presents the system event view (iOS EventKitUI). Returns false when the
  /// platform cannot present it or the event cannot be found.
  @async
  bool presentEventView(String eventIdentifier);

  @async
  List<EventKitReminder> getReminders(String? predicate);

  @async
  List<EventKitReminder> getIncompleteReminders(
    List<String>? calendarIdentifiers,
    EventKitDateTime? startDate,
    EventKitDateTime? endDate,
  );

  @async
  List<EventKitReminder> getCompletedReminders(
    List<String>? calendarIdentifiers,
    EventKitDateTime? startDate,
    EventKitDateTime? endDate,
  );

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

// MARK: - Compatibility HostApis (subset of EventKitHostApi)

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
  String saveEvent(EventKitEvent event, EventKitSpan span);
  @async
  bool removeEvent(String identifier, EventKitSpan span);
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

enum EventKitSpan { thisEvent, futureEvents }

enum EventKitCalendarType { local, calDAV, exchange, subscription, birthday }

enum EventKitSourceType {
  local,
  calDAV,
  exchange,
  mobileMe,
  subscribed,
  birthdays,
}

enum EventKitParticipantStatus {
  unknown,
  pending,
  accepted,
  declined,
  tentative,
  delegated,
  completed,
  inProcess,
}

enum EventKitParticipantRole {
  unknown,
  required,
  optional,
  chair,
  nonParticipant,
}

enum EventKitParticipantType { unknown, person, room, resource, group }

enum EventKitAlarmProximity { none, enter, leave }

// MARK: - Data Classes

/// Wall-clock date-time components (not UTC unless the event time zone is UTC).
///
/// Instant identity for sync lives on [EventKitEvent.startDateUnixMs] /
/// [EventKitEvent.endDateUnixMs].
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

class EventKitStructuredLocation {
  String? title;
  double? latitude;
  double? longitude;
  double? radius;

  EventKitStructuredLocation({
    this.title,
    this.latitude,
    this.longitude,
    this.radius,
  });
}

class EventKitParticipant {
  String? name;
  String? url;
  String? email;
  EventKitParticipantStatus status;
  EventKitParticipantRole role;
  EventKitParticipantType type;
  bool isCurrentUser;

  EventKitParticipant({
    this.name,
    this.url,
    this.email,
    required this.status,
    required this.role,
    required this.type,
    required this.isCurrentUser,
  });
}

class EventKitAlarm {
  double? relativeOffsetSeconds;
  EventKitDateTime? absoluteDate;
  EventKitAlarmProximity proximity;
  EventKitStructuredLocation? structuredLocation;

  EventKitAlarm({
    this.relativeOffsetSeconds,
    this.absoluteDate,
    this.proximity = EventKitAlarmProximity.none,
    this.structuredLocation,
  });
}

class EventKitRecurrenceDayOfWeek {
  /// EKWeekday: 1 = Sunday … 7 = Saturday.
  int dayOfTheWeek;

  /// 0 = every matching weekday; otherwise the Nth (or -Nth) week.
  int weekNumber;

  EventKitRecurrenceDayOfWeek({
    required this.dayOfTheWeek,
    this.weekNumber = 0,
  });
}

class EventKitRecurrenceRule {
  EventKitRecurrenceFrequency frequency;
  int interval;
  EventKitDateTime? endDate;
  int? occurrenceCount;
  List<EventKitRecurrenceDayOfWeek?>? daysOfTheWeek;
  List<int?>? daysOfTheMonth;
  List<int?>? daysOfTheYear;
  List<int?>? weeksOfTheYear;
  List<int?>? monthsOfTheYear;
  List<int?>? setPositions;

  /// Read-only on EKRecurrenceRule (0 = unset, 1–7 = EKWeekday).
  int? firstDayOfTheWeek;

  EventKitRecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.endDate,
    this.occurrenceCount,
    this.daysOfTheWeek,
    this.daysOfTheMonth,
    this.daysOfTheYear,
    this.weeksOfTheYear,
    this.monthsOfTheYear,
    this.setPositions,
    this.firstDayOfTheWeek,
  });
}

class EventKitCalendar {
  String identifier;
  String title;
  String? color;
  EventKitCalendarType type;

  /// Compatibility alias of [sourceTitle].
  String? source;
  String? sourceTitle;
  String? sourceIdentifier;
  EventKitSourceType sourceType;

  bool isEditable;
  bool isSubscribed;
  bool isImmutable;
  String? externalId;

  EventKitCalendar({
    required this.identifier,
    required this.title,
    this.color,
    required this.type,
    this.source,
    this.sourceTitle,
    this.sourceIdentifier,
    required this.sourceType,
    required this.isEditable,
    required this.isSubscribed,
    required this.isImmutable,
    this.externalId,
  });
}

class EventKitEvent {
  /// EKEvent.eventIdentifier. Same value as [eventIdentifier].
  String? identifier;
  String? eventIdentifier;
  String? calendarItemIdentifier;
  String? calendarItemExternalIdentifier;

  String title;
  String? notes;
  String? location;
  String? url;
  EventKitStructuredLocation? structuredLocation;

  EventKitDateTime startDate;
  EventKitDateTime endDate;

  /// IANA name (e.g. "Europe/Berlin"). Null/empty = floating (typical for all-day).
  String? timeZone;
  int? startDateUnixMs;
  int? endDateUnixMs;
  bool isAllDay;

  EventKitDateTime? occurrenceDate;
  int? occurrenceDateUnixMs;
  bool? isDetached;

  EventKitEventAvailability availability;
  EventKitEventStatus status;

  int? creationDateUnixMs;
  EventKitDateTime? creationDate;
  int? lastModifiedDateUnixMs;
  EventKitDateTime? lastModifiedDate;

  String? birthdayContactIdentifier;
  String? calendarId;

  EventKitParticipant? organizer;
  List<EventKitParticipant?>? attendees;
  List<EventKitAlarm?>? alarms;
  List<EventKitRecurrenceRule?>? recurrenceRules;

  /// Derived from [attendees] emails when reading. Not written to EventKit.
  List<String?>? attendeeEmails;

  /// First of [recurrenceRules] when reading. Written only if [recurrenceRules] is null.
  EventKitRecurrenceRule? recurrenceRule;

  EventKitEvent({
    this.identifier,
    this.eventIdentifier,
    this.calendarItemIdentifier,
    this.calendarItemExternalIdentifier,
    required this.title,
    this.notes,
    this.location,
    this.url,
    this.structuredLocation,
    required this.startDate,
    required this.endDate,
    this.timeZone,
    this.startDateUnixMs,
    this.endDateUnixMs,
    this.isAllDay = false,
    this.occurrenceDate,
    this.occurrenceDateUnixMs,
    this.isDetached,
    this.availability = EventKitEventAvailability.busy,
    this.status = EventKitEventStatus.none,
    this.creationDateUnixMs,
    this.creationDate,
    this.lastModifiedDateUnixMs,
    this.lastModifiedDate,
    this.birthdayContactIdentifier,
    this.calendarId,
    this.organizer,
    this.attendees,
    this.alarms,
    this.recurrenceRules,
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
