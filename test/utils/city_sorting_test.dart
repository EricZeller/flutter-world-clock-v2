import 'package:flutter_test/flutter_test.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/utils/city_sorting.dart';
import 'package:world_clock_v2/utils/place_names.dart';

City _city(String name, String country, String timeZone, String utc,
        {bool custom = false, String flag = ''}) =>
    City(
      name: name,
      country: country,
      timeZone: timeZone,
      flag: flag,
      utc: utc,
      weatherZone: name,
      isCustom: custom,
    );

void main() {
  final tokyo = _city('Tokyo', 'Japan', 'Asia/Tokyo', '+09:00');
  final berlin = _city('Berlin', 'Germany', 'Europe/Berlin', '+02:00');
  final caracas = _city('Caracas', 'Venezuela', 'America/Caracas', '-04:00');
  final stJohns =
      _city("St. John's", 'Canada', 'America/St_Johns', '-02:30');
  final home = _city('Zuhause', '', 'Europe/Berlin', '+02:00', custom: true);
  final cities = [tokyo, berlin, caracas, stJohns, home];

  group('sortCities', () {
    test('sorts by name with custom cities first', () {
      expect(sortCities(cities, CitySort.city),
          [home, berlin, caracas, stJohns, tokyo]);
    });

    test('sorts by country', () {
      expect(sortCities(cities, CitySort.country),
          [home, stJohns, berlin, tokyo, caracas]);
    });

    test('sorts by UTC offset from west to east', () {
      expect(sortCities(cities, CitySort.utc),
          [home, caracas, stJohns, berlin, tokyo]);
    });

    test('sorts by time zone region', () {
      expect(sortCities(cities, CitySort.continent),
          [home, caracas, stJohns, tokyo, berlin]);
    });

    test('does not modify the input list', () {
      final input = [tokyo, berlin];
      sortCities(input, CitySort.city);
      expect(input, [tokyo, berlin]);
    });
  });

  group('compareUtc', () {
    test('orders negative offsets before positive ones', () {
      expect(compareUtc('-05:00', '-03:00'), lessThan(0));
      expect(compareUtc('-01:00', '+01:00'), lessThan(0));
      expect(compareUtc('+05:30', '+05:00'), greaterThan(0));
      expect(compareUtc('+02:00', '+02:00'), 0);
    });
  });

  group('filterCities', () {
    test('matches name, country, time zone and UTC case-insensitively', () {
      expect(filterCities(cities, 'tok'), [tokyo]);
      expect(filterCities(cities, 'GERMANY'), [berlin]);
      expect(filterCities(cities, 'america/'), [caracas, stJohns]);
      expect(filterCities(cities, '+02:00'), [berlin, home]);
    });

    test('returns everything for an empty query', () {
      expect(filterCities(cities, '  '), cities);
    });
  });

  group('in German', () {
    const german = PlaceNames('de');
    final vienna = _city('Vienna', 'Austria', 'Europe/Vienna', '+02:00',
        flag: 'at.webp');
    final warsaw = _city('Warsaw', 'Poland', 'Europe/Warsaw', '+02:00',
        flag: 'pl.webp');
    final munich = _city('Munich', 'Germany', 'Europe/Berlin', '+02:00',
        flag: 'de.webp');
    final berlin = _city('Berlin', 'Germany', 'Europe/Berlin', '+02:00',
        flag: 'de.webp');
    final beijing = _city('Beijing', 'China', 'Asia/Shanghai', '+08:00',
        flag: 'cn.webp');
    final saoTome = _city('São Tomé', 'Sao Tome and Principe',
        'Africa/Sao_Tome', '+00:00',
        flag: 'st.webp');
    final cities = [vienna, warsaw, munich, berlin, beijing, saoTome];

    test('cities are found by their German and English names', () {
      expect(filterCities(cities, 'deutschland', german), [munich, berlin]);
      expect(filterCities(cities, 'germany', german), [munich, berlin]);
      expect(filterCities(cities, 'München', german), [munich]);
      expect(filterCities(cities, 'muenchen', german), [munich]);
      expect(filterCities(cities, 'Peking', german), [beijing]);
      expect(filterCities(cities, 'warschau', german), [warsaw]);
      expect(filterCities(cities, 'österreich', german), [vienna]);
      expect(filterCities(cities, 'oesterreich', german), [vienna]);
    });

    test('diacritics do not matter', () {
      expect(filterCities(cities, 'sao tome', german), [saoTome]);
      expect(filterCities(cities, 'SÃO TOMÉ', german), [saoTome]);
      expect(filterCities(cities, 'sao tome', PlaceNames.english), [saoTome]);
    });

    test('English finds no German names', () {
      expect(filterCities(cities, 'deutschland'), isEmpty);
      expect(filterCities(cities, 'peking'), isEmpty);
    });

    test('sorting by country uses the German names', () {
      expect(sortCities(cities, CitySort.country, german).map((c) => c.name), [
        'Beijing', // China
        'Berlin', // Deutschland, by city within the country
        'Munich',
        'Vienna', // Österreich, sorted as O
        'Warsaw', // Polen
        'São Tomé', // São Tomé und Príncipe
      ]);
      expect(sortCities(cities, CitySort.country).map((c) => c.name), [
        'Vienna', // Austria
        'Beijing', // China
        'Berlin', // Germany
        'Munich',
        'Warsaw', // Poland
        'São Tomé', // Sao Tome and Principe
      ]);
    });
  });
}
