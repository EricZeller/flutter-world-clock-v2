import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
}
