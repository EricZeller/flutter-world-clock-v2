import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:world_clock_v2/data/place_names.g.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/models/country_zone.dart';
import 'package:world_clock_v2/utils/search.dart';

// If one of these fails, run: dart run tool/generate_place_names.dart
void main() {
  final cities =
      jsonDecode(File('assets/data/cities.json').readAsStringSync()) as List;
  final codes = {
    for (final city in cities) CountryZone.countryCode(city['flag'] as String),
  };
  final languages = {
    for (final locale in AppLocalizations.supportedLocales)
      locale.languageCode,
  };

  test('exist for every language of the app', () {
    expect(countryNames.keys.toSet(), languages);
    expect(languages.difference(cityExonyms.keys.toSet()), {'en'},
        reason: 'English is the language the cities are named in');
  });

  test('name every country of the bundled cities in every language', () {
    for (final language in languages) {
      final names = countryNames[language]!;
      expect(names.keys.toSet(), codes, reason: language);
      expect(
        names.entries.where((entry) => entry.value.trim().isEmpty),
        isEmpty,
        reason: language,
      );
    }
  });

  test('keep the English names of cities.json', () {
    for (final city in cities) {
      final code = CountryZone.countryCode(city['flag'] as String);
      expect(countryNames['en']![code], city['country'], reason: code);
    }
  });

  test('translate the countries', () {
    expect(countryNames['de']!['de'], 'Deutschland');
    expect(countryNames['es']!['de'], 'Alemania');
    expect(countryNames['fr']!['de'], 'Allemagne');
    expect(countryNames['pt']!['de'], 'Alemanha');
    expect(countryNames['de']!['hk'], 'China',
        reason: 'Hong Kong is listed as China, like in English');
    expect(countryNames['pt']!['br'], 'Brasil');
    expect(countryNames['de']!['cz'], 'Tschechien',
        reason: 'the usual name, which German users search for');
  });

  test('are the same in the macOS widget', () {
    // A Windows checkout may use CRLF line endings.
    final swift = File('macos/WorldClockWidget/CountryNames.swift')
        .readAsStringSync()
        .replaceAll('\r\n', '\n');
    for (final language in languages.difference({'en'})) {
      final block = [
        '        "$language": [',
        for (final MapEntry(key: code, value: name)
            in countryNames[language]!.entries)
          '            "$code": "$name",',
        '        ],',
      ].join('\n');
      expect(swift, contains(block), reason: language);
    }
  });

  test('give other names only for bundled cities', () {
    final keys = {
      for (final city in cities)
        '${city['name']}|${CountryZone.countryCode(city['flag'] as String)}',
    };
    for (final MapEntry(key: language, value: exonyms)
        in cityExonyms.entries) {
      expect(keys.containsAll(exonyms.keys), isTrue, reason: language);
      for (final MapEntry(key: city, value: other) in exonyms.entries) {
        expect(other, isNotEmpty, reason: '$language: $city');
        expect(other.where((name) => name.contains('­')), isEmpty,
            reason: 'soft hyphens are removed');
      }
    }
    expect(cityExonyms['de']!['Munich|de'], ['München']);
    expect(cityExonyms['de']!['Beijing|cn'], ['Peking']);
    expect(cityExonyms['de']!['Moscow|ru'], ['Moskau']);
    expect(cityExonyms['fr']!['London|gb'], ['Londres']);
  });

  test('show the cities in the other languages', () {
    final keys = {
      for (final city in cities)
        '${city['name']}|${CountryZone.countryCode(city['flag'] as String)}',
    };
    expect(cityNames.keys.toSet(), languages.difference({'en'}));
    for (final MapEntry(key: language, value: shown) in cityNames.entries) {
      expect(keys.containsAll(shown.keys), isTrue, reason: language);
      for (final MapEntry(key: key, value: name) in shown.entries) {
        final city = key.split('|').first;
        expect(name, isNot(city), reason: '$language: $key');
        expect(name.trim(), isNotEmpty, reason: '$language: $key');
        expect(
          matchesSearch(
            searchTextOf([city, ...?cityExonyms[language]![key]]),
            name,
          ),
          isTrue,
          reason: 'the shown name $name is found by the search',
        );
      }
    }
    expect(cityNames['de']!['Munich|de'], 'München');
    expect(cityNames['de']!['Cologne|de'], 'Köln');
    expect(cityNames['es']!['Cologne|de'], 'Colonia');
    expect(cityNames['pt']!['Munich|de'], 'Munique');
    expect(cityNames['de']!['Beijing|cn'], 'Peking', reason: 'extraCityNames');
    expect(cityNames['es']!['Berlin|de'], 'Berlín', reason: 'CLDR');
    expect(cityNames['de']!['Berlin|de'], isNull);
    expect(cityNames['de']!['Hamburg|de'], isNull);
    expect(cityNames['fr']!['Hyderabad|in'], isNull,
        reason: 'the Hyderabad of India is not named after the Pakistani one');
    expect(cityNames['fr']!['Valencia|es'], 'Valence');
    expect(cityNames['fr']!['Hyderabad|pk'], isNull,
        reason: 'Hyderâbâd is a transliteration');
  });

  test('name the cities of GeoNames in the other languages', () {
    expect(cityExonyms['de']!['Cologne|de'], ['Köln']);
    expect(cityExonyms['es']!['Cologne|de'], ['Colonia']);
    expect(cityExonyms['pt']!['Munich|de'], ['Munique']);
    expect(cityExonyms['fr']!['Hamburg|de'], ['Hambourg']);
    expect(cityExonyms['de']!['Hamburg|de'], isNull,
        reason: 'Hamburg is Hamburg in German');
    expect(cityExonyms['de']!['Kyiv|ua'], containsAll(['Kiew', 'Kyjiw']));
  });
}
