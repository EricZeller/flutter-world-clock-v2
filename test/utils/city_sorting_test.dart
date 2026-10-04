import 'package:flutter_test/flutter_test.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/utils/city_sorting.dart';

City _city(String name, String country, String timeZone, String utc,
        {bool custom = false}) =>
    City(
      name: name,
      country: country,
      timeZone: timeZone,
      flag: '',
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
}
