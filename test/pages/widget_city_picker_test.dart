import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/pages/widget_city_picker.dart';

import '../helpers/home_widget_recorder.dart';
import '../helpers/test_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  bool isMarked(WidgetTester tester, String name) => tester
      .widget<ListTile>(find.ancestor(
        of: find.text(name).first,
        matching: find.byType(ListTile),
      ))
      .selected;

  testWidgets('lists the favorites first and marks the widget city',
      (tester) async {
    final repository = FakeCityRepository();
    await repository.saveFavorites([tokyo]);

    await pumpPage(tester, const WidgetCityPickerPage(widgetId: 5),
        settings: await loadSettings(), cities: repository);

    expect(find.text('Your cities'), findsOneWidget);
    expect(find.text('Tokyo'), findsNWidgets(2));
    expect(isMarked(tester, 'Tokyo'), isTrue,
        reason: 'a new widget shows the first favorite');
    expect(isMarked(tester, 'Berlin'), isFalse);
  });

  testWidgets('choosing a city saves it and ends the configuration',
      (tester) async {
    final widget = HomeWidgetRecorder.install()..installedWidgetIds = [5];
    final repository = FakeCityRepository();
    await pumpPage(tester, const WidgetCityPickerPage(widgetId: 5),
        settings: await loadSettings(), cities: repository);

    await tester.tap(find.text('Tokyo'));
    await tester.pump(const Duration(seconds: 2));

    expect(await repository.loadWidgetCities(), {5: tokyo});
    expect(widget.current['city_5'], 'Tokyo');
    expect(widget.methods.last, 'finishHomeWidgetConfigure');
  });

  testWidgets('reconfiguring marks the current city of the widget',
      (tester) async {
    final repository = FakeCityRepository();
    await repository.saveWidgetCity(5, tokyo);

    await pumpPage(tester, const WidgetCityPickerPage(widgetId: 5),
        settings: await loadSettings(), cities: repository);

    expect(isMarked(tester, 'Tokyo'), isTrue);
    expect(isMarked(tester, 'Berlin'), isFalse);
  });
}
