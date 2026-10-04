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
}
