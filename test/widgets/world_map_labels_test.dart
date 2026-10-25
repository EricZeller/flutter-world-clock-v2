import 'package:flutter_test/flutter_test.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/widgets/world_map/world_map_painter.dart';

City city({int? population, bool isCapital = false, bool isCustom = false}) =>
    City(
      name: 'Somewhere',
      country: 'Germany',
      timeZone: 'Europe/Berlin',
      flag: 'de.webp',
      utc: '+02:00',
      weatherZone: 'Somewhere',
      population: population,
      isCapital: isCapital,
      isCustom: isCustom,
    );

/// The zoom level from which the name of [city] is drawn.
double labelFrom(City city) => [
  1.0,
  1.6,
  3.0,
  5.0,
].firstWhere((scale) => isLabelVisible(city, isSelected: false, scale: scale));

void main() {
  group('isMarkerVisible', () {
    test('draws big cities, capitals and custom cities at every zoom', () {
      for (final big in [
        city(population: 1000000),
        city(population: 1000, isCapital: true),
        city(isCustom: true),
        city(),
      ]) {
        expect(isMarkerVisible(big, isSelected: false, scale: 1), isTrue);
      }
    });

    test('draws smaller cities once zoomed in', () {
      final small = city(population: 600000);
      expect(isMarkerVisible(small, isSelected: false, scale: 1), isFalse);
      expect(isMarkerVisible(small, isSelected: false, scale: 2), isTrue);
      expect(isMarkerVisible(small, isSelected: true, scale: 1), isTrue);
    });
  });

  group('isLabelVisible', () {
    test('labels a selected city at every zoom level', () {
      expect(
        isLabelVisible(city(population: 1000), isSelected: true, scale: 1),
        isTrue,
      );
    });

    test('labels bigger cities sooner', () {
      expect(labelFrom(city(population: 8000000)), 1.6);
      expect(labelFrom(city(population: 2000000)), 3.0);
      expect(labelFrom(city(population: 600000)), 5.0);
    });

    test('labels capitals like big cities', () {
      expect(labelFrom(city(population: 50000, isCapital: true)), 3.0);
    });

    test('labels custom cities like metropolises', () {
      expect(labelFrom(city(isCustom: true)), 1.6);
    });

    test('labels a city of an older version without population late', () {
      expect(labelFrom(city()), 5.0);
    });
  });
}
