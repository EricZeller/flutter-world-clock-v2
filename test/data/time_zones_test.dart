import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:world_clock_v2/models/country_zone.dart';
import 'package:world_clock_v2/services/city_repository.dart';
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

  // If one of these fails, run: dart run tool/generate_time_zones.dart
  group('the time zones of the countries', () {
    final countryZones = CountryZone.parseAll(
      File(CityRepository.countryZonesAsset).readAsStringSync(),
    );
    final flags = {for (final city in cities) city['flag'] as String};

    test('are all in the shipped database', () {
      final missing = [
        for (final MapEntry(:key, :value) in countryZones.entries)
          for (final zone in value)
            if (!tz.timeZoneDatabase.locations.containsKey(zone.timeZone))
              '$key: ${zone.timeZone}',
      ];
      expect(missing, isEmpty);
    });

    test('exist for every country of the bundled cities', () {
      final codes = flags.map(CountryZone.countryCode).toSet();
      expect(
        codes.difference(countryZones.keys.toSet()),
        {'xk'},
        reason:
            'Kosovo has no zone of its own in the tz database and '
            'offers the zone of its city',
      );
      expect(
        countryZones.keys.toSet().difference(codes),
        isEmpty,
        reason: 'only countries of the app are bundled',
      );
    });

    test('include the zones of the bundled cities of the country', () {
      final missing = [
        for (final city in cities)
          if (countryZones[CountryZone.countryCode(city['flag'] as String)]
              case final zones?)
            if (!zones.any((zone) => zone.timeZone == city['timeZone']))
              '${city['name']} (${city['timeZone']})',
      ];
      expect(
        missing,
        isEmpty,
        reason:
            'an alias such as Europe/Kyiv is listed under the name '
            'its cities use, Europe/Kiev',
      );
    });

    test('offer all zones of large countries', () {
      List<String> zonesOf(String code) => [
        for (final zone in countryZones[code]!) zone.timeZone,
      ];

      expect(
        zonesOf('ca'),
        containsAll([
          'America/Vancouver',
          'America/Toronto',
          'America/Halifax',
          'America/St_Johns',
        ]),
      );
      expect(
        zonesOf('au'),
        containsAll(['Australia/Perth', 'Australia/Sydney']),
      );
      expect(
        zonesOf('ru'),
        containsAll(['Europe/Moscow', 'Asia/Novosibirsk', 'Asia/Vladivostok']),
      );
      expect(zonesOf('us'), hasLength(greaterThan(20)));
      expect(zonesOf('hk'), ['Asia/Hong_Kong']);
      expect(
        zonesOf('ua'),
        unorderedEquals(['Europe/Kiev', 'Europe/Simferopol']),
      );
    });

    test('have the coordinates of their principal location', () {
      for (final zones in countryZones.values) {
        for (final zone in zones) {
          expect(zone.latitude, inInclusiveRange(-90, 90));
          expect(zone.longitude, inInclusiveRange(-180, 180));
        }
      }
      final perth = countryZones['au']!.singleWhere(
        (zone) => zone.timeZone == 'Australia/Perth',
      );
      expect(perth.latitude, closeTo(-31.95, 0.01));
      expect(perth.longitude, closeTo(115.85, 0.01));
      expect(perth.comment, 'Western Australia (most areas)');
    });
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
