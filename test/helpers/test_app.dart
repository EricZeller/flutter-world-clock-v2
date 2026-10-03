import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/services/city_repository.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:world_clock_v2/services/weather_service.dart';

import 'fake_wttr.dart';

const tokyo = City(
  name: 'Tokyo',
  country: 'Japan',
  timeZone: 'Asia/Tokyo',
  flag: 'jp.png',
  utc: '+09:00',
  weatherZone: 'Tokyo',
);

/// City repository with a small in-memory city list instead of the asset.
class FakeCityRepository extends CityRepository {
  FakeCityRepository([this.cities = const [City.berlin, tokyo]]);

  final List<City> cities;

  @override
  Future<List<City>> loadAllCities() async =>
      [...cities, ...await loadCustomCities()];
}

/// Pumps [page] inside a localized MaterialApp with all app providers.
Future<void> pumpPage(
  WidgetTester tester,
  Widget page, {
  required SettingsProvider settings,
  WeatherService? weather,
  CityRepository? cities,
  Locale locale = const Locale('en'),
}) async {
  // A tall phone-like screen so whole pages fit without scrolling.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        Provider<CityRepository>.value(value: cities ?? FakeCityRepository()),
        Provider<WeatherService>.value(value: weather ?? FakeWttr().service),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: page,
        routes: {
          '/location': (_) => const Scaffold(body: Text('location route')),
          '/settings': (_) => const Scaffold(body: Text('settings route')),
          '/widget_settings': (_) => const Scaffold(body: Text('widgets')),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<SettingsProvider> loadSettings() async {
  final settings = SettingsProvider();
  await settings.load();
  return settings;
}
