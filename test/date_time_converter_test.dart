import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_event_kit/src/date_time_converter.dart';

void main() {
  group('DateTimeConverter', () {
    test('round-trips wall-clock components', () {
      final original = DateTime(2026, 9, 6, 14, 30, 5, 250);
      final pigeon = DateTimeConverter.toPigeon(original);
      final back = DateTimeConverter.toDart(pigeon);

      expect(back.year, original.year);
      expect(back.month, original.month);
      expect(back.day, original.day);
      expect(back.hour, original.hour);
      expect(back.minute, original.minute);
      expect(back.second, original.second);
      expect(back.millisecond, original.millisecond);
    });

    test('utcFromUnixMs reads UTC instants', () {
      const ms = 1700000000000;
      final parsed = DateTimeConverter.utcFromUnixMs(ms);
      expect(parsed, isNotNull);
      expect(parsed!.isUtc, isTrue);
      expect(parsed.millisecondsSinceEpoch, ms);
      expect(DateTimeConverter.utcFromUnixMs(null), isNull);
    });
  });
}
