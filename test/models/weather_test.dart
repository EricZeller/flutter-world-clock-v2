import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:world_clock_v2/models/weather.dart';
import 'package:world_clock_v2/utils/weather_symbols.dart';

import '../helpers/fake_wttr.dart';

void main() {
  final fetchedAt = DateTime(2026, 10, 3, 17, 20);
  final json = jsonDecode(wttrBerlinFixture) as Map<String, dynamic>;

  WeatherReport parse({String? lang}) =>
      WeatherReport.fromWttr(json, fetchedAt: fetchedAt, lang: lang);

  group('WeatherReport.fromWttr', () {
    test('parses the current conditions', () {
      final current = parse(lang: 'de').current;

      expect(current.code, 119);
      expect(current.symbol, '☁️');
      expect(current.description, 'Wolkig');
      expect(current.temperature(false), 20);
      expect(current.temperature(true), 68);
      expect(current.feelsLike(false), 20);
      expect(current.feelsLike(true), 68);
      expect(current.humidity, 60);
      expect(current.windKmph, 5);
      expect(current.windMph, 3);
    });

    test('falls back to the trimmed English description', () {
      expect(parse().current.description, 'Cloudy');
      expect(parse(lang: 'xx').current.description, 'Cloudy');
    });

    test('parses three days with astronomy and hourly forecasts', () {
      final report = parse(lang: 'de');

      expect(report.days, hasLength(3));
      final today = report.today!;
      expect(today.date, DateTime(2026, 10, 3));
      expect(today.min(false), 15);
      expect(today.max(false), 20);
      expect(today.min(true), 59);
      expect(today.max(true), 69);
      expect(today.sunrise, '07:11 AM');
      expect(today.sunset, '06:39 PM');
      expect(today.hours, hasLength(8));
      expect(today.hours.map((hour) => hour.hour),
          [0, 3, 6, 9, 12, 15, 18, 21]);
      expect(today.hours[3].description, 'Örtlich Regen');
      expect(today.chanceOfRain, 27);
      expect(today.representative!.hour, 12);
      expect(today.representative!.description, 'Bedeckt');
    });

    test('tolerates missing optional fields', () {
      final report = WeatherReport.fromWttr({
        'current_condition': [
          {'temp_C': '5', 'weatherCode': '113'}
        ],
        'weather': [
          {'date': '2026-01-01'}
        ],
      }, fetchedAt: fetchedAt);

      expect(report.current.tempC, 5);
      expect(report.current.description, '');
      expect(report.today!.sunrise, '');
      expect(report.today!.hours, isEmpty);
      expect(report.today!.representative, isNull);
      expect(report.today!.chanceOfRain, 0);
      expect(report.current.uvIndex, isNull);
      expect(report.today!.uvIndex, isNull);
      expect(report.today!.moonPhase, isNull);
      expect(report.today!.moonIllumination, isNull);
    });
  });

  group('UV index and moon phase', () {
    WeatherReport parseWith({Object? uvIndex, Object? phase, Object? lit}) =>
        WeatherReport.fromWttr({
          'current_condition': [
            {'uvIndex': uvIndex}
          ],
          'weather': [
            {
              'date': '2026-01-01',
              'uvIndex': uvIndex,
              'astronomy': [
                {'moon_phase': phase, 'moon_illumination': lit}
              ],
            }
          ],
        }, fetchedAt: fetchedAt);

    test('are parsed for now and each day', () {
      final report = parse();

      expect(report.current.uvIndex, 0);
      expect([for (final day in report.days) day.uvIndex], [2, 2, 1]);
      expect([for (final day in report.days) day.moonPhase], [
        MoonPhase.lastQuarter,
        MoonPhase.waningCrescent,
        MoonPhase.waningCrescent,
      ]);
      expect([for (final day in report.days) day.moonIllumination],
          [53, 42, 32]);
    });

    test('accept numbers and padded strings', () {
      final report =
          parseWith(uvIndex: 7, phase: ' Full Moon ', lit: ' 100 ');

      expect(report.current.uvIndex, 7);
      expect(report.today!.uvIndex, 7);
      expect(report.today!.moonPhase, MoonPhase.fullMoon);
      expect(report.today!.moonIllumination, 100);
    });

    test('stay unknown for garbage', () {
      for (final garbage in ['', 'n/a', '4.5', 'Blue Moon', 'full moon']) {
        final report =
            parseWith(uvIndex: garbage, phase: garbage, lit: garbage);

        expect(report.current.uvIndex, isNull, reason: garbage);
        expect(report.today!.uvIndex, isNull, reason: garbage);
        expect(report.today!.moonPhase, isNull, reason: garbage);
        expect(report.today!.moonIllumination, isNull, reason: garbage);
      }
    });

    test('know all eight phases wttr.in sends', () {
      expect(
          [
            for (final name in [
              'New Moon',
              'Waxing Crescent',
              'First Quarter',
              'Waxing Gibbous',
              'Full Moon',
              'Waning Gibbous',
              'Last Quarter',
              'Waning Crescent',
            ])
              MoonPhase.fromWttr(name)
          ],
          MoonPhase.values);
      expect([for (final phase in MoonPhase.values) phase.symbol],
          ['🌑', '🌒', '🌓', '🌔', '🌕', '🌖', '🌗', '🌘']);
    });

    test('UV risk follows the WHO scale', () {
      expect([for (var index = 0; index <= 12; index++) UvRisk.of(index)], [
        UvRisk.low,
        UvRisk.low,
        UvRisk.low,
        UvRisk.moderate,
        UvRisk.moderate,
        UvRisk.moderate,
        UvRisk.high,
        UvRisk.high,
        UvRisk.veryHigh,
        UvRisk.veryHigh,
        UvRisk.veryHigh,
        UvRisk.extreme,
        UvRisk.extreme,
      ]);
    });

    test('survive the cache', () {
      final restored =
          WeatherReport.fromJson(jsonDecode(jsonEncode(parse().toJson())));

      expect(restored.current.uvIndex, 0);
      expect(restored.today!.uvIndex, 2);
      expect(restored.today!.moonPhase, MoonPhase.lastQuarter);
      expect(restored.today!.moonIllumination, 53);
    });

    test('older caches without them still load', () {
      final json = jsonDecode(jsonEncode(parse().toJson()));
      (json['current'] as Map).remove('uvIndex');
      for (final day in json['days'] as List) {
        day
          ..remove('uvIndex')
          ..remove('moonPhase')
          ..remove('moonIllumination');
      }

      final restored = WeatherReport.fromJson(json);

      expect(restored.current.uvIndex, isNull);
      expect(restored.today!.uvIndex, isNull);
      expect(restored.today!.moonPhase, isNull);
      expect(restored.today!.moonIllumination, isNull);
      expect(restored.summary(fahrenheit: false), '☁️ Cloudy +20°C');
    });

    test('an unknown cached phase is dropped', () {
      final json = jsonDecode(jsonEncode(parse().toJson()));
      (json['days'] as List).first['moonPhase'] = 'blueMoon';

      expect(WeatherReport.fromJson(json).today!.moonPhase, isNull);
    });
  });

  group('summary', () {
    test('matches the wttr.in one-line format', () {
      expect(parse(lang: 'de').summary(fahrenheit: false), '☁️ Wolkig +20°C');
      expect(parse().summary(fahrenheit: true), '☁️ Cloudy +68°F');
    });

    test('formats temperatures with sign', () {
      expect(formatTemperature(18, fahrenheit: false), '+18°C');
      expect(formatTemperature(0, fahrenheit: false), '0°C');
      expect(formatTemperature(-3, fahrenheit: true), '-3°F');
    });
  });

  test('survives a JSON round trip for the cache', () {
    final report = parse(lang: 'de');

    final restored =
        WeatherReport.fromJson(jsonDecode(jsonEncode(report.toJson())));

    expect(restored.toJson(), report.toJson());
    expect(restored.fetchedAt, fetchedAt);
    expect(restored.summary(fahrenheit: false), '☁️ Wolkig +20°C');
  });

  group('upcomingHours', () {
    test('starts with the running slot and continues into the next day', () {
      final slots = parse().upcomingHours(DateTime.utc(2026, 10, 3, 17, 19));

      expect(slots, hasLength(8));
      expect(slots.first.time, DateTime.utc(2026, 10, 3, 18));
      expect(slots.first.forecast.tempC, 20);
      expect(slots[2].time, DateTime.utc(2026, 10, 4, 0));
      expect(slots.last.time, DateTime.utc(2026, 10, 4, 15));
    });

    test('includes a slot that started less than 90 minutes ago', () {
      final slots = parse().upcomingHours(DateTime.utc(2026, 10, 3, 16));

      expect(slots.first.time, DateTime.utc(2026, 10, 3, 15));
    });

    test('is empty when the forecast is outdated', () {
      expect(parse().upcomingHours(DateTime.utc(2026, 11, 1)), isEmpty);
    });
  });

  group('weatherSymbol', () {
    test('uses the wttr.in emoji', () {
      expect(weatherSymbol(113), '☀️');
      expect(weatherSymbol(116), '⛅️');
      expect(weatherSymbol(176), '🌦');
      expect(weatherSymbol(389), '🌩');
      expect(weatherSymbol(999), '✨');
    });
  });

  group('night', () {
    // Berlin, 2026-10-03: sunrise 07:11, sunset 18:39 local time (UTC+2).
    final noon = DateTime.utc(2026, 10, 3, 10);
    final midnight = DateTime.utc(2026, 10, 3, 22);

    test('a clear sky shows the moon at night', () {
      expect(weatherSymbol(113, night: true), '🌙');
      expect(weatherSymbol(116, night: true), '☁️');
      expect(weatherSymbol(119, night: true), '☁️');
      expect(weatherSymbol(176, night: true), '🌧');
      expect(weatherSymbol(266, night: true), '🌧');
      expect(weatherSymbol(176), '🌦');
      expect(weatherSymbol(113), '☀️');
    });

    test('the current symbol follows the sun at the weather location', () {
      final json = jsonDecode(wttrBerlinFixture) as Map<String, dynamic>;
      (json['current_condition'] as List).first['weatherCode'] = '113';
      final current = WeatherReport.fromWttr(json, fetchedAt: fetchedAt).current;

      expect(current.location, (latitude: 52.517, longitude: 13.4));
      expect(current.symbolAt(noon), '☀️');
      expect(current.symbolAt(midnight), '🌙');
    });

    test('without a location the sun is assumed', () {
      final report = WeatherReport.fromWttr({
        'current_condition': [
          {'weatherCode': '113'}
        ],
      }, fetchedAt: fetchedAt);

      expect(report.current.symbolAt(midnight), '☀️');
    });

    test('hours before sunrise and after sunset are night', () {
      final today = parse().today!;

      expect([for (final hour in today.hours) hour.isNight],
          [true, true, true, false, false, false, false, true]);
    });

    group('without sunrise or sunset', () {
      // Tromsø, where the sun does not rise in December and does not set
      // in June.
      WeatherReport polar(
        String date, {
        bool withLocation = true,
        String latitude = '69.649',
        String longitude = '18.957',
        String sunrise = 'No sunrise',
        String sunset = 'No sunset',
      }) =>
          WeatherReport.fromWttr({
            'current_condition': [
              {'weatherCode': '113'}
            ],
            if (withLocation)
              'nearest_area': [
                {'latitude': latitude, 'longitude': longitude}
              ],
            'weather': [
              {
                'date': date,
                'astronomy': [
                  {'sunrise': sunrise, 'sunset': sunset}
                ],
                'hourly': [
                  for (var hour = 0; hour < 24; hour += 3)
                    {'time': '${hour * 100}', 'weatherCode': '113'}
                ],
              }
            ],
          }, fetchedAt: fetchedAt);

      List<bool> nights(WeatherReport report) =>
          [for (final hour in report.today!.hours) hour.isNight];

      test('polar night has night all day', () {
        final report = polar('2026-12-15');

        expect(nights(report), everyElement(isTrue));
        expect(report.today!.hours[4].symbol, '🌙');
        final restored =
            WeatherReport.fromJson(jsonDecode(jsonEncode(report.toJson())));
        expect(nights(restored), everyElement(isTrue));
      });

      test('polar day has day all day', () {
        expect(nights(polar('2026-06-21')), everyElement(isFalse));
      });

      test('without a location the sun is assumed', () {
        expect(nights(polar('2026-12-15', withLocation: false)),
            everyElement(isFalse));
      });

      test('do not depend on how far the clocks are from the sun', () {
        // Longyearbyen keeps Central European (summer) time, about an hour
        // ahead of the sun; McMurdo keeps New Zealand time on the south.
        WeatherReport longyearbyen(String date) =>
            polar(date, latitude: '78.000', longitude: '16.000');
        WeatherReport mcMurdo(String date) =>
            polar(date, latitude: '-77.846', longitude: '166.676');

        expect(nights(longyearbyen('2026-04-23')), everyElement(isFalse));
        expect(nights(longyearbyen('2026-06-21')), everyElement(isFalse));
        expect(nights(longyearbyen('2026-08-22')), everyElement(isFalse));
        expect(nights(longyearbyen('2026-12-15')), everyElement(isTrue));
        expect(nights(mcMurdo('2026-06-21')), everyElement(isTrue));
        expect(nights(mcMurdo('2026-12-21')), everyElement(isFalse));
      });

      test('a sunrise without a sunset is night only before it', () {
        // Tromsø on the day the midnight sun begins.
        expect(nights(polar('2026-05-18', sunrise: '01:24 AM')),
            [true, false, false, false, false, false, false, false]);
      });

      test('a sunset without a sunrise is night only after it', () {
        expect(nights(polar('2026-07-28', sunset: '08:30 PM')),
            [false, false, false, false, false, false, false, true]);
      });

      test('a short night after midnight is only night until sunrise', () {
        // The sun sets at 00:40 and rises again at 03:30.
        final report =
            polar('2026-07-27', sunrise: '03:30 AM', sunset: '12:40 AM');
        expect(nights(report),
            [false, true, false, false, false, false, false, false]);
      });
    });

    test('survives the cache', () {
      final report = parse();
      final restored =
          WeatherReport.fromJson(jsonDecode(jsonEncode(report.toJson())));

      expect(restored.current.location, report.current.location);
      expect(restored.today!.hours.first.isNight, isTrue);
      expect(restored.today!.hours[4].isNight, isFalse);
    });

    test('older caches without a location still load', () {
      final json = parse().toJson();
      (json['current'] as Map).remove('latitude');
      (json['current'] as Map).remove('longitude');

      expect(WeatherReport.fromJson(json).current.location, isNull);
    });
  });
}
