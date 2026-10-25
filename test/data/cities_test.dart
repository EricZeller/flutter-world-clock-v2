import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:world_clock_v2/models/country_zone.dart';
import 'package:world_clock_v2/utils/search.dart';

// The bundled cities as tool/generate_cities.dart writes them. If one of
// these fails after editing cities.json by hand, run the generator.
void main() {
  final cities = [
    for (final city
        in jsonDecode(File('assets/data/cities.json').readAsStringSync())
            as List)
      city as Map<String, dynamic>,
  ];
  String describe(Map<String, dynamic> city) =>
      '${city['name']}, ${city['country']}';

  test('are hundreds of cities in nearly every country', () {
    expect(cities.length, greaterThan(700));
    final countries = {for (final city in cities) city['flag']};
    expect(countries.length, greaterThan(180));
  });

  test('have a GeoNames id each, no two the same', () {
    final ids = <int>{};
    for (final city in cities) {
      expect(city['id'], isA<int>(), reason: describe(city));
      expect(
        ids.add(city['id'] as int),
        isTrue,
        reason: '${describe(city)} shares its id',
      );
    }
  });

  test('are told apart by name, country and time zone', () {
    // What City's == compares, and so what tells favorites apart.
    final seen = <String>{};
    for (final city in cities) {
      final identity = '${city['name']}|${city['country']}|${city['timeZone']}';
      expect(
        seen.add(identity),
        isTrue,
        reason: '${describe(city)} is listed twice',
      );
    }
  });

  test('have coordinates, which the weather is looked up by', () {
    for (final city in cities) {
      final latitude = city['latitude'] as num;
      final longitude = city['longitude'] as num;
      expect(latitude, inInclusiveRange(-90, 90), reason: describe(city));
      expect(longitude, inInclusiveRange(-180, 180), reason: describe(city));
      expect(
        city['weatherZone'],
        '${latitude.toStringAsFixed(2)},${longitude.toStringAsFixed(2)}',
        reason: describe(city),
      );
    }
  });

  test('have a population', () {
    // GeoNames gives Ngerulmud, the capital of Palau, none.
    for (final city in cities) {
      expect(city['population'], isA<int>(), reason: describe(city));
      expect(
        city['population'],
        greaterThanOrEqualTo(0),
        reason: describe(city),
      );
    }
  });

  test('include the capital of every country', () {
    final capitals = {
      for (final city in cities)
        if (city['capital'] == true) city['flag'] as String,
    };
    final countries = {for (final city in cities) city['flag'] as String};
    expect(countries.difference(capitals), {
      'il.webp',
      'ps.webp',
    }, reason: 'GeoNames marks no capital of Israel and Palestine');
    for (final city in cities) {
      expect(city['capital'], anyOf(isNull, isTrue), reason: describe(city));
    }
  });

  test('have names in English, not in a transliteration', () {
    final marks = RegExp('[āēīōūĀĒĪŌŪ’‘]|\'\$');
    for (final city in cities) {
      expect(city['name'], isNot(matches(marks)), reason: describe(city));
      expect(
        (city['name'] as String).trim(),
        city['name'],
        reason: describe(city),
      );
    }
  });

  test('name their country like the other cities of the country', () {
    final countries = <String, String>{};
    for (final city in cities) {
      final code = CountryZone.countryCode(city['flag'] as String);
      final country = city['country'] as String;
      expect(
        countries.putIfAbsent(code, () => country),
        country,
        reason: describe(city),
      );
    }
  });

  test('are sorted by country, then by name', () {
    final sorted = [...cities]
      ..sort((a, b) {
        final byCountry = compareNames(
          a['country'] as String,
          b['country'] as String,
        );
        return byCountry != 0
            ? byCountry
            : compareNames(a['name'] as String, b['name'] as String);
      });
    expect(cities.map(describe), sorted.map(describe));
  });

  test('keep the cities of earlier versions', () {
    // Favorites saved with them keep matching the bundled city.
    final identities = {
      for (final city in cities)
        '${city['name']}|${city['country']}|${city['timeZone']}',
    };
    for (final identity in const [
      'Berlin|Germany|Europe/Berlin',
      'Furtwangen|Germany|Europe/Berlin',
      'New York|United States|America/New_York',
      'Washington, D.C.|United States|America/New_York',
      'Kyiv|Ukraine|Europe/Kiev',
      'Hanoi|Vietnam|Asia/Ho_Chi_Minh',
      'Manila|Philippines|Asia/Manila',
      'Canberra|Australia|Australia/Sydney',
    ]) {
      expect(identities, contains(identity));
    }
  });
}
