import 'package:flutter_test/flutter_test.dart';
import 'package:world_clock_v2/models/city.dart';

void main() {
  group('City', () {
    test('is created from JSON', () {
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
      expect(city.latitude, isNull);
      expect(city.isCustom, isFalse);
    });

    test('is converted to JSON', () {
      final json = City.berlin.toJson();

      expect(json['name'], equals('Berlin'));
      expect(json['country'], equals('Germany'));
      expect(json['timeZone'], equals('Europe/Berlin'));
      expect(json['flag'], equals('de.png'));
      expect(json['utc'], equals('+02:00'));
      expect(json['weatherZone'], equals('Berlin'));
    });

    test('survives a JSON round trip including custom fields', () {
      const city = City(
        name: 'Home',
        country: '',
        timeZone: 'Europe/Berlin',
        flag: '',
        utc: '+02:00',
        weatherZone: 'Home',
        latitude: 52.5,
        longitude: 13.4,
        isCustom: true,
      );

      final restored = City.fromJson(city.toJson());

      expect(restored, equals(city));
      expect(restored.latitude, 52.5);
      expect(restored.longitude, 13.4);
      expect(restored.isCustom, isTrue);
    });

    test('compares by identity fields, not by reference', () {
      final restored = City.fromJson(City.berlin.toJson());
      const custom = City(
        name: 'Berlin',
        country: 'Germany',
        timeZone: 'Europe/Berlin',
        flag: 'de.png',
        utc: '+02:00',
        weatherZone: 'Berlin',
        isCustom: true,
      );

      expect(restored, equals(City.berlin));
      expect(restored.hashCode, equals(City.berlin.hashCode));
      expect(custom, isNot(equals(City.berlin)));
    });
  });
}
