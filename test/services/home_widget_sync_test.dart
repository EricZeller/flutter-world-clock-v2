import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/services/city_repository.dart';
import 'package:world_clock_v2/services/home_widget_sync.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:world_clock_v2/services/weather_service.dart';

import '../helpers/fake_wttr.dart';
import '../helpers/home_widget_recorder.dart';
import '../helpers/test_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Runs one sync through a page so it has a real BuildContext.
  Future<void> sync(WidgetTester tester, {WeatherService? weather}) async {
    await pumpPage(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => HomeWidgetSync(
            cities: context.read<CityRepository>(),
            weather: context.read<WeatherService>(),
          ).sync(context, context.read<SettingsProvider>()),
          child: const Text('sync'),
        ),
      ),
      settings: await loadSettings(),
      weather: weather,
    );
    await tester.tap(find.text('sync'));
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('widgets without their own city show the first favorite',
      (tester) async {
    final widget = HomeWidgetRecorder.install();
    await CityRepository().saveFavorites([tokyo, City.berlin]);

    await sync(tester);

    expect(widget.current['city'], 'Tokyo');
    expect(widget.current['timeZone'], 'Asia/Tokyo');
    expect(widget.current['weather'], '☁️ Cloudy +20°C');
    expect(widget.methods.last, 'updateWidget');
  });

  testWidgets('a widget with its own city gets suffixed keys',
      (tester) async {
    final widget = HomeWidgetRecorder.install()..installedWidgetIds = [7, 8];
    await CityRepository().saveWidgetCity(7, tokyo);

    await sync(tester);

    expect(widget.current['city'], 'Berlin');
    expect(widget.current['city_7'], 'Tokyo');
    expect(widget.current['timeZone_7'], 'Asia/Tokyo');
    expect(widget.current['weather_icon_7'], '☁️');
    expect(widget.current['weather_temp_7'], '20°');
    expect(widget.current['city_8'], isNull,
        reason: 'widget 8 follows the first favorite');
  });

  testWidgets('a widget that lost its own city shows the first favorite',
      (tester) async {
    final widget = HomeWidgetRecorder.install()..installedWidgetIds = [7];

    await sync(tester);

    expect(widget.valuesOf('city_7'), [null]);
    expect(widget.valuesOf('timeZone_7'), [null]);
    expect(widget.current['city'], 'Berlin');
  });

  testWidgets('removed widgets are forgotten', (tester) async {
    final widget = HomeWidgetRecorder.install()..installedWidgetIds = [7];
    final repository = CityRepository();
    await repository.saveWidgetCity(7, tokyo);
    await repository.saveWidgetCity(9, City.berlin);

    await sync(tester);

    expect(await repository.loadWidgetCities(), {7: tokyo});
    expect(widget.valuesOf('city_9'), [null]);
  });

  testWidgets('keeps all widget cities when the installed widgets are unknown',
      (tester) async {
    HomeWidgetRecorder.install().installedWidgetIds = null;
    final repository = CityRepository();
    await repository.saveWidgetCity(9, City.berlin);

    await sync(tester);

    expect(await repository.loadWidgetCities(), {9: City.berlin});
  });

  testWidgets('shows the status when a widget city has no weather',
      (tester) async {
    final widget = HomeWidgetRecorder.install()..installedWidgetIds = [7];
    await CityRepository().saveWidgetCity(7, tokyo);

    await sync(tester, weather: FakeWttr(offline: true).service);

    expect(widget.current['weather_7'], '🛜 Connection error');
    expect(widget.current['weather_icon_7'], '🛜');
    expect(widget.current['weather_temp_7'], '');
  });
}
