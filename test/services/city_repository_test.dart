import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/services/city_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const custom = City(
    name: 'Zuhause',
    country: '',
    timeZone: 'Europe/Berlin',
    flag: '',
    utc: '+02:00',
    weatherZone: 'Zuhause',
    isCustom: true,
  );

  late CityRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = CityRepository();
  });

  test('loads the bundled cities', () async {
    final cities = await repository.loadAllCities();

    expect(cities.length, greaterThan(100));
    expect(cities, contains(City.berlin));
    expect(cities.where((city) => city.isCustom), isEmpty);
  });

  test('appends saved custom cities to the bundled ones', () async {
    await repository.saveCustomCities([custom]);

    final cities = await repository.loadAllCities();

    expect(cities.last, custom);
    expect(await repository.loadCustomCities(), [custom]);
  });

  test('stores and restores the selected city', () async {
    expect(await repository.loadSelectedCity(), isNull);

    await repository.saveSelectedCity(custom);

    expect(await repository.loadSelectedCity(), custom);
  });

  test('ignores broken stored data', () async {
    SharedPreferences.setMockInitialValues({
      CityRepository.selectedCityKey: '{not json',
      CityRepository.customCitiesKey: '[{"name": 1}]',
    });

    expect(await repository.loadSelectedCity(), isNull);
    expect(await repository.loadCustomCities(), isEmpty);
  });

  group('favorites', () {
    test('start with Berlin on a fresh install', () async {
      expect(await repository.loadFavorites(), [City.berlin]);
    });

    test('take over the single city of older versions', () async {
      await repository.saveSelectedCity(custom);

      expect(await repository.loadFavorites(), [custom]);
    });

    test('are stored in order and keep the first as selection', () async {
      await repository.saveFavorites([custom, City.berlin]);

      expect(await repository.loadFavorites(), [custom, City.berlin]);
      expect(await repository.loadSelectedCity(), custom);
    });

    test('ignore duplicates and fall back on broken data', () async {
      SharedPreferences.setMockInitialValues({
        CityRepository.favoritesKey: jsonEncode(
            [City.berlin.toJson(), custom.toJson(), City.berlin.toJson()]),
      });
      expect(await repository.loadFavorites(), [City.berlin, custom]);

      SharedPreferences.setMockInitialValues({
        CityRepository.favoritesKey: '[]',
        CityRepository.selectedCityKey: jsonEncode(custom.toJson()),
      });
      expect(await repository.loadFavorites(), [custom]);
    });

    test('remember the city shown last', () async {
      expect(await repository.loadCurrentIndex(), 0);
      await repository.saveCurrentIndex(2);
      expect(await repository.loadCurrentIndex(), 2);
    });
  });

  group('widget cities', () {
    test('are stored per widget and can be removed', () async {
      expect(await repository.loadWidgetCities(), isEmpty);

      await repository.saveWidgetCity(7, custom);
      await repository.saveWidgetCity(9, City.berlin);
      await repository.saveWidgetCity(7, City.berlin);
      expect(await repository.loadWidgetCities(),
          {7: City.berlin, 9: City.berlin});

      await repository.removeWidgetCities([9, 42]);
      expect(await repository.loadWidgetCities(), {7: City.berlin});
    });

    test('follow an edited or deleted custom city', () async {
      const renamed = City(
        name: 'Daheim',
        country: '',
        timeZone: 'Asia/Tokyo',
        flag: '',
        utc: '+09:00',
        weatherZone: 'Daheim',
        isCustom: true,
      );
      await repository.saveWidgetCity(7, custom);
      await repository.saveWidgetCity(8, custom);
      await repository.saveWidgetCity(9, City.berlin);

      await repository.replaceWidgetCity(custom, renamed);
      expect(await repository.loadWidgetCities(),
          {7: renamed, 8: renamed, 9: City.berlin});

      await repository.replaceWidgetCity(renamed, null);
      expect(await repository.loadWidgetCities(), {9: City.berlin});
    });

    test('ignore broken data', () async {
      SharedPreferences.setMockInitialValues(
          {CityRepository.widgetCitiesKey: '{"x": 1}'});

      expect(await repository.loadWidgetCities(), isEmpty);
    });

    test('include those saved by another instance of the app', () async {
      expect(await repository.loadWidgetCities(), isEmpty);

      // Android runs the widget configuration in a second instance, which
      // writes to the platform behind this instance's cache.
      await SharedPreferencesStorePlatform.instance.setValue(
          'String',
          'flutter.${CityRepository.widgetCitiesKey}',
          jsonEncode({'5': custom.toJson()}));

      expect(await repository.loadWidgetCities(), {5: custom});
    });
  });
}
