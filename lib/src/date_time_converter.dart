import 'dart:core' as dart;
import 'messages.g.dart';

/// Utility class for converting between Dart's DateTime and Pigeon's EKDateTime
class DateTimeConverter {
  /// Convert Dart DateTime to Pigeon EKDateTime
  static EventKitDateTime toPigeon(dart.DateTime dartDateTime) {
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

  /// Convert Pigeon EKDateTime to Dart DateTime
  static dart.DateTime toDart(EventKitDateTime pigeonDateTime) {
    return dart.DateTime(
      pigeonDateTime.year,
      pigeonDateTime.month,
      pigeonDateTime.day,
      pigeonDateTime.hour,
      pigeonDateTime.minute,
      pigeonDateTime.second,
      pigeonDateTime.millisecond,
    );
  }

  /// Convert nullable Dart DateTime to nullable Pigeon EKDateTime
  static EventKitDateTime? toPigeonNullable(dart.DateTime? dartDateTime) {
    return dartDateTime != null ? toPigeon(dartDateTime) : null;
  }

  /// Convert nullable Pigeon EKDateTime to nullable Dart DateTime
  static dart.DateTime? toDartNullable(EventKitDateTime? pigeonDateTime) {
    return pigeonDateTime != null ? toDart(pigeonDateTime) : null;
  }
}
