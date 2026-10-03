import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:world_clock_v2/utils/time_utils.dart';

import '../helpers/time_zones.dart';

void main() {
  setUpAll(initializeAppTimeZones);

  final cities =
      jsonDecode(File('assets/data/cities.json').readAsStringSync()) as List;

  test('every bundled city has a time zone in the shipped database', () {
    // If this fails, run: dart run tool/generate_time_zones.dart
    final missing = [
      for (final city in cities)
        if (!tz.timeZoneDatabase.locations.containsKey(city['timeZone']))
          '${city['name']} (${city['timeZone']})',
    ];
    expect(missing, isEmpty);
  });

  test('alias zones keep their daylight saving rules', () {
    Duration offset(String zone, DateTime utc) =>
        tz.TZDateTime.from(utc, tz.getLocation(zone)).timeZoneOffset;
    final summer = DateTime.utc(2026, 7, 1);
    final winter = DateTime.utc(2026, 1, 15);

    expect(offset('Europe/Stockholm', summer), const Duration(hours: 2));
    expect(offset('Europe/Amsterdam', winter), const Duration(hours: 1));
    expect(offset('Europe/Kiev', summer), const Duration(hours: 3));
    expect(offset('Africa/Accra', summer), Duration.zero);
    expect(offset('America/St_Lucia', winter), const Duration(hours: -4));
    expect(offset('America/New_York', summer), const Duration(hours: -4));
    expect(offset('Australia/Sydney', winter), const Duration(hours: 11));
  });

  test('unknown zones fall back to UTC instead of throwing', () {
    expect(findLocation('Mars/Olympus_Mons'), tz.UTC);
    expect(
      formatTimeInZone('Mars/Olympus_Mons',
          use24hr: true, showSeconds: false, now: DateTime.utc(2026, 1, 1, 9)),
      '09:00',
    );
  });
}
