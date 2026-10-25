import 'package:flutter_test/flutter_test.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/utils/place_names.dart';
import 'package:world_clock_v2/utils/search.dart';

City _city(
  String name,
  String country,
  String flag, {
  bool custom = false,
}) =>
    City(
      name: name,
      country: country,
      timeZone: 'Europe/Berlin',
      flag: flag,
      utc: '+02:00',
      weatherZone: name,
      isCustom: custom,
    );

void main() {
  const german = PlaceNames('de');
  final munich = _city('Munich', 'Germany', 'de.webp');
  final hongKong = _city('Hong Kong', 'China', 'hk.webp');

  group('country', () {
    test('is translated by the flag', () {
      expect(german.country(munich), 'Deutschland');
      expect(const PlaceNames('fr').country(hongKong), 'Chine');
      expect(const PlaceNames('pt').country(munich), 'Alemanha');
    });

    test('stays as it is in English', () {
      expect(PlaceNames.english.country(munich), 'Germany');
      expect(PlaceNames.english.country(hongKong), 'China');
    });

    test('falls back to English for other languages', () {
      expect(const PlaceNames('it').country(munich), 'Germany');
    });

    test('of a custom city with a bundled country is translated', () {
      expect(german.country(_city('Zuhause', 'Germany', 'de.webp',
          custom: true)), 'Deutschland');
    });

    test('of an older custom city is shown as entered', () {
      // Older versions saved any text with any flag.
      expect(german.country(_city('Zuhause', 'Bayern', 'de.webp',
          custom: true)), 'Bayern');
      expect(german.country(_city('Zuhause', 'Atlantis', 'xx.webp',
          custom: true)), 'Atlantis');
      expect(german.country(_city('Zuhause', 'Atlantis', '', custom: true)),
          'Atlantis');
      expect(german.country(_city('Zuhause', '', '', custom: true)), '');
    });
  });

  group('name', () {
    test('is the one of the language', () {
      expect(german.name(munich), 'München');
      expect(const PlaceNames('pt').name(munich), 'Munique');
      expect(const PlaceNames('fr').name(munich), 'Munich');
      expect(PlaceNames.english.name(munich), 'Munich');
    });

    test('of a custom city is shown as entered', () {
      final custom = _city('Munich', 'Germany', 'de.webp', custom: true);
      expect(german.name(custom), 'Munich');
    });
  });

  test('details show the country and the offset', () {
    expect(german.details(City.berlin), 'Deutschland, UTC+02:00');
    expect(PlaceNames.english.details(City.berlin), 'Germany, UTC+02:00');
    expect(german.details(_city('Zuhause', '', '', custom: true)),
        'UTC+02:00');
  });

  group('searchText', () {
    test('finds a city by its names and countries', () {
      final text = german.searchText(munich);
      for (final query in [
        'munich',
        'München',
        'muenchen',
        'germany',
        'deutschland',
        'europe/berlin',
        '+02:00',
      ]) {
        expect(matchesSearch(text, query), isTrue, reason: query);
      }
    });

    test('uses the names of the language and English only', () {
      expect(matchesSearch(german.searchText(munich), 'alemania'), isFalse);
      expect(
          matchesSearch(PlaceNames.english.searchText(munich), 'deutschland'),
          isFalse);
    });

    test('of a custom city has no other names', () {
      final custom = _city('Munich', 'Germany', 'de.webp', custom: true);
      expect(matchesSearch(german.searchText(custom), 'münchen'), isFalse);
      expect(matchesSearch(german.searchText(custom), 'deutschland'), isTrue);
    });
  });
}
