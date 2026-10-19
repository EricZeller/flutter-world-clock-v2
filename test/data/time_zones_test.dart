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

  test('every bundled city lists the offset of 1 July as its utc', () {
    // Custom cities without a bundled city in their zone get the same, see
    // listedUtcOffset.
    final wrong = [
      for (final city in cities)
        if (city['utc'] != listedUtcOffset(city['timeZone'] as String))
          '${city['name']} (${city['timeZone']}): ${city['utc']}, expected '
              '${listedUtcOffset(city['timeZone'] as String)}',
    ];
    expect(wrong, isEmpty);
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

    test('fold zones that have had the same time since 1981', () {
      final germany = countryZones['de']!;
      expect(germany.map((zone) => zone.timeZone), ['Europe/Berlin']);
      expect(germany.single.comment, isEmpty,
          reason: 'the only zone of a country needs no comment');
      expect(germany.single.sameTime, {'Europe/Busingen': 'Busingen'});

      final newYork = countryZones['us']!.singleWhere(
        (zone) => zone.timeZone == 'America/New_York',
      );
      expect(newYork.comment, 'Eastern (most areas)');
      expect(newYork.sameTime.keys,
          containsAll(['America/Detroit', 'America/Kentucky/Louisville']));
      expect(
        countryZones['es']!.map((zone) => zone.timeZone),
        ['Europe/Madrid', 'Africa/Ceuta', 'Atlantic/Canary'],
        reason: 'Ceuta had other rules until the 1980s',
      );
    });

    test('keep the folded zones in the shipped database', () {
      // Custom cities may have been saved with them.
      Duration offset(String zone, int at) =>
          tz.getLocation(zone).timeZone(at).offset;
      // The offsets only change at transitions, so comparing them at every
      // transition of both zones in the shipped data covers all instants.
      List<int> instants(String a, String b) => [
        DateTime.utc(2000).millisecondsSinceEpoch,
        ...tz.getLocation(a).transitionAt,
        ...tz.getLocation(b).transitionAt,
      ];
      final offered = {
        for (final zones in countryZones.values)
          for (final zone in zones) zone.timeZone,
      };
      final wrong = <String>[];
      for (final zones in countryZones.values) {
        for (final zone in zones) {
          for (final folded in zone.sameTime.keys) {
            if (!tz.timeZoneDatabase.locations.containsKey(folded)) {
              wrong.add('$folded is not shipped');
            } else if (offered.contains(folded)) {
              wrong.add('$folded is offered as well');
            } else if (instants(folded, zone.timeZone).any((at) =>
                offset(folded, at) != offset(zone.timeZone, at))) {
              wrong.add('$folded differs from ${zone.timeZone}');
            }
          }
        }
      }
      expect(wrong, isEmpty);
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

  test('a custom city saved with Europe/Busingen keeps its time', () {
    for (final now in [
      DateTime.utc(2026, 1, 15, 9),
      DateTime.utc(2026, 7, 1, 9),
    ]) {
      expect(
        formatTimeInZone('Europe/Busingen',
            use24hr: true, showSeconds: false, now: now),
        formatTimeInZone('Europe/Berlin',
            use24hr: true, showSeconds: false, now: now),
      );
    }
    expect(findLocation('Europe/Busingen').name, 'Europe/Busingen');
    expect(
      formatTimeInZone('Europe/Busingen',
          use24hr: true, showSeconds: false, now: DateTime.utc(2026, 7, 1, 9)),
      '11:00',
    );
  });

  test('the shipped database has the 2026 rules of western Canada', () {
    // If this fails, package:timezone is older than tzdata 2026e or the
    // asset was not regenerated: dart run tool/generate_time_zones.dart
    Duration offset(String zone, DateTime utc) =>
        tz.TZDateTime.from(utc, tz.getLocation(zone)).timeZoneOffset;
    final december = DateTime.utc(2026, 12);

    expect(offset('America/Vancouver', december), const Duration(hours: -7));
    expect(offset('America/Edmonton', december), const Duration(hours: -6));
    expect(offset('America/Winnipeg', december), const Duration(hours: -5));
    expect(offset('America/Inuvik', december), const Duration(hours: -6));
    expect(offset('Europe/Berlin', december), const Duration(hours: 1));
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
