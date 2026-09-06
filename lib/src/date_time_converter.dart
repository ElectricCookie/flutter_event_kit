import 'messages.g.dart';

/// Converts between Dart [DateTime] and Pigeon [EventKitDateTime].
///
/// [EventKitDateTime] stores **wall-clock** components in the event's IANA
/// time zone (or the device zone when the event is floating / all-day).
/// Instant identity for sync is [EventKitEvent.startDateUnixMs] /
/// [EventKitEvent.endDateUnixMs] (UTC milliseconds since epoch).
class DateTimeConverter {
  /// Wall-clock components of [dartDateTime] in that DateTime's calendar.
  static EventKitDateTime toPigeon(DateTime dartDateTime) {
    return EventKitDateTime(
      year: dartDateTime.year,
      month: dartDateTime.month,
      day: dartDateTime.day,
      hour: dartDateTime.hour,
      minute: dartDateTime.minute,
      second: dartDateTime.second,
      millisecond: dartDateTime.millisecond,
    );
  }

  /// Interprets [pigeonDateTime] as a local (wall-clock) Dart DateTime.
  static DateTime toDart(EventKitDateTime pigeonDateTime) {
    return DateTime(
      pigeonDateTime.year,
      pigeonDateTime.month,
      pigeonDateTime.day,
      pigeonDateTime.hour,
      pigeonDateTime.minute,
      pigeonDateTime.second,
      pigeonDateTime.millisecond,
    );
  }

  /// UTC instant from EventKit unix milliseconds.
  static DateTime? utcFromUnixMs(int? unixMs) {
    if (unixMs == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(unixMs, isUtc: true);
  }

  static EventKitDateTime? toPigeonNullable(DateTime? dartDateTime) {
    return dartDateTime != null ? toPigeon(dartDateTime) : null;
  }

  static DateTime? toDartNullable(EventKitDateTime? pigeonDateTime) {
    return pigeonDateTime != null ? toDart(pigeonDateTime) : null;
  }
}
