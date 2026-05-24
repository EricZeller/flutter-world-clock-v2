import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_clock_v2/pages/location.dart';

void main() {
  group('City Model Tests', () {
    test('City should be created from JSON', () {
      const cityJson = {
        'name': 'Berlin',
        'country': 'Germany',
        'timeZone': 'Europe/Berlin',
        'flag': 'de.png',
        'utc': '+02:00',
        'weatherZone': 'Berlin'
      };

      final city = City.fromJson(cityJson);

      expect(city.name, equals('Berlin'));
      expect(city.country, equals('Germany'));
      expect(city.timeZone, equals('Europe/Berlin'));
      expect(city.flag, equals('de.png'));
      expect(city.utc, equals('+02:00'));
      expect(city.weatherZone, equals('Berlin'));
    });

    test('City should be converted to JSON', () {
      final city = City(
        name: 'Berlin',
        country: 'Germany',
        timeZone: 'Europe/Berlin',
        flag: 'de.png',
        utc: '+02:00',
        weatherZone: 'Berlin',
      );

      final json = city.toJson();

      expect(json['name'], equals('Berlin'));
      expect(json['country'], equals('Germany'));
      expect(json['timeZone'], equals('Europe/Berlin'));
      expect(json['flag'], equals('de.png'));
      expect(json['utc'], equals('+02:00'));
      expect(json['weatherZone'], equals('Berlin'));
    });
  });
}
