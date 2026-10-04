import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:world_clock_v2/utils/time_utils.dart';

import '../helpers/time_zones.dart';

void main() {
  setUpAll(() async {
    initializeAppTimeZones();
    await initializeDateFormatting();
  });

  // 2026-07-01 12:34:56 UTC, during daylight saving time in Europe and the US.
  final summer = DateTime.utc(2026, 7, 1, 12, 34, 56);
  // 2026-01-15 08:05:09 UTC, standard time.
  final winter = DateTime.utc(2026, 1, 15, 8, 5, 9);

  group('formatTimeInZone', () {
    test('formats 24h time with and without seconds', () {
      expect(
        formatTimeInZone('Europe/Berlin',
            use24hr: true, showSeconds: true, now: summer),
        '14:34:56',
      );
      expect(
        formatTimeInZone('Asia/Tokyo',
            use24hr: true, showSeconds: false, now: summer),
        '21:34',
      );
    });

    test('formats 12h time', () {
      expect(
        formatTimeInZone('America/New_York',
            use24hr: false, showSeconds: false, now: summer),
        '08:34 AM',
      );
      expect(
        formatTimeInZone('Asia/Kolkata',
            use24hr: false, showSeconds: true, now: winter),
        '01:35:09 PM',
      );
    });

    test('respects daylight saving time', () {
      expect(
        formatTimeInZone('Europe/Berlin',
            use24hr: true, showSeconds: false, now: winter),
        '09:05',
      );
    });
  });

  group('differenceToLocal', () {
    test('is the zone offset minus the local offset', () {
      final local = summer.toLocal();
      expect(
        differenceToLocal('Asia/Tokyo', now: local),
        const Duration(hours: 9) - local.timeZoneOffset,
      );
      expect(
        differenceToLocal('Asia/Kolkata', now: local),
        const Duration(hours: 5, minutes: 30) - local.timeZoneOffset,
      );
    });
  });

  group('formatOffset', () {
    test('formats positive, negative and zero offsets', () {
      expect(formatOffset(const Duration(hours: 2)), '+02:00');
      expect(formatOffset(const Duration(hours: -5, minutes: -30)), '-05:30');
      expect(formatOffset(Duration.zero), '+00:00');
      expect(formatOffset(const Duration(hours: 13, minutes: 45)), '+13:45');
    });
  });

  group('parseUtcOffset', () {
    test('parses offsets into minutes', () {
      expect(parseUtcOffset('+02:00'), 120);
      expect(parseUtcOffset('-03:30'), -210);
      expect(parseUtcOffset('+00:00'), 0);
    });

    test('returns null for malformed values', () {
      expect(parseUtcOffset('UTC'), isNull);
      expect(parseUtcOffset(''), isNull);
    });
  });

  group('formatWttrTime', () {
    test('converts wttr.in times to the clock format', () {
      expect(formatWttrTime('07:11 AM', use24hr: true), '07:11');
      expect(formatWttrTime('06:39 PM', use24hr: true), '18:39');
      expect(formatWttrTime('12:05 AM', use24hr: true), '00:05');
      expect(formatWttrTime('06:39 PM', use24hr: false), '06:39 PM');
    });

    test('returns null when there is no sunrise or sunset', () {
      expect(formatWttrTime('No sunrise', use24hr: true), isNull);
      expect(formatWttrTime('No sunset', use24hr: false), isNull);
    });
  });

  group('formatUpdateTime', () {
    final now = DateTime(2026, 10, 3, 18, 0);

    test('shows only the time for today', () {
      expect(
        formatUpdateTime(DateTime(2026, 10, 3, 17, 5),
            use24hr: true, locale: 'en', now: now),
        '17:05',
      );
      expect(
        formatUpdateTime(DateTime(2026, 10, 3, 17, 5),
            use24hr: false, locale: 'en', now: now),
        '05:05 PM',
      );
    });

    test('adds the date for older updates', () {
      expect(
        formatUpdateTime(DateTime(2026, 10, 1, 9, 30),
            use24hr: true, locale: 'en', now: now),
        'Oct 1, 09:30',
      );
      expect(
        formatUpdateTime(DateTime(2026, 10, 1, 9, 30),
            use24hr: true, locale: 'de', now: now),
        '1. Okt., 09:30',
      );
    });
  });

  group('wallClockIn', () {
    test('returns the local wall-clock time of the zone', () {
      expect(wallClockIn('Asia/Tokyo', now: summer),
          DateTime.utc(2026, 7, 1, 21, 34, 56));
      expect(wallClockIn('America/New_York', now: winter),
          DateTime.utc(2026, 1, 15, 3, 5, 9));
    });
  });

  group('calendarDaysBetween', () {
    test('counts calendar days regardless of the time of day', () {
      expect(calendarDaysBetween(DateTime(2026, 10, 3, 23, 59),
          DateTime(2026, 10, 4, 0, 1)), 1);
      expect(calendarDaysBetween(DateTime(2026, 10, 3), DateTime(2026, 10, 3)),
          0);
      expect(calendarDaysBetween(DateTime(2026, 10, 3), DateTime(2026, 10, 5)),
          2);
    });

    test('is not affected by daylight saving changes of the device', () {
      // Local dates around the European spring and autumn changes.
      expect(calendarDaysBetween(DateTime(2026, 3, 28), DateTime(2026, 3, 29)),
          1);
      expect(calendarDaysBetween(DateTime(2026, 3, 29), DateTime(2026, 3, 30)),
          1);
      expect(
          calendarDaysBetween(DateTime(2026, 10, 24), DateTime(2026, 10, 25)),
          1);
    });
  });
}
