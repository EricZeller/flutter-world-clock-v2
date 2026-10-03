import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/pages/location/location_page.dart';
import 'package:world_clock_v2/services/city_repository.dart';

import '../helpers/test_app.dart';

const newYork = City(
  name: 'New York',
  country: 'United States',
  timeZone: 'America/New_York',
  flag: 'us.png',
  utc: '-04:00',
  weatherZone: 'New York',
);

Finder get timeZoneField => find.descendant(
      of: find.widgetWithText(DropdownMenu<String>, 'IANA time zone'),
      matching: find.byType(TextField),
    );

Finder get flagField => find.descendant(
      of: find.widgetWithText(DropdownMenu<String>, 'Flag (optional)'),
      matching: find.byType(TextField),
    );

/// Labels of the entries the open dropdown menu currently offers.
List<String> menuEntries() => find
    .descendant(
      of: find.byType(MenuItemButton).hitTestable(),
      matching: find.byType(Text),
    )
    .evaluate()
    .map((element) => (element.widget as Text).data!)
    .toList();

void main() {
  RadioListTile<City> tileFor(WidgetTester tester, String name) =>
      tester.widget<RadioListTile<City>>(
        find.ancestor(
          of: find.text(name),
          matching: find.byType(RadioListTile<City>),
        ),
      );

  bool isSelected(WidgetTester tester, String name) {
    final group = tester.widget<RadioGroup<City>>(find.byType(RadioGroup<City>));
    return group.groupValue == tileFor(tester, name).value;
  }

  testWidgets('marks the stored city as selected', (tester) async {
    SharedPreferences.setMockInitialValues({
      'selectedOption': jsonEncode(tokyo.toJson()),
    });

    await pumpPage(tester, const LocationPage(),
        settings: await loadSettings());

    expect(isSelected(tester, 'Tokyo'), isTrue);
    expect(isSelected(tester, 'Berlin'), isFalse);
  });

  testWidgets('selecting a city stores it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = FakeCityRepository();
    await pumpPage(tester, const LocationPage(),
        settings: await loadSettings(), cities: repository);
    expect(isSelected(tester, 'Berlin'), isTrue);

    await tester.tap(find.text('Tokyo'));
    await tester.pumpAndSettle();

    expect(isSelected(tester, 'Tokyo'), isTrue);
    expect(await repository.loadSelectedCity(), tokyo);
  });

  testWidgets('search filters the list', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpPage(tester, const LocationPage(),
        settings: await loadSettings());
    expect(find.text('Search city or country (2 found)'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'japan');
    await tester.pump();

    expect(find.text('Search city or country (1 found)'), findsOneWidget);
    expect(find.text('Berlin'), findsNothing);
    expect(find.text('Tokyo'), findsOneWidget);
  });

  testWidgets('adds a custom city and selects it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = FakeCityRepository();
    await pumpPage(tester, const LocationPage(),
        settings: await loadSettings(), cities: repository);

    await tester.tap(find.byTooltip('Add custom city'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'City name'), 'Zuhause');
    await tester.enterText(timeZoneField, 'tokyo');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Asia/Tokyo').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Zuhause'), findsOneWidget);
    expect(isSelected(tester, 'Zuhause'), isTrue);
    final custom = await repository.loadCustomCities();
    expect(custom.single.name, 'Zuhause');
    expect(custom.single.timeZone, 'Asia/Tokyo');
    expect(custom.single.isCustom, isTrue);
    expect(await repository.loadSelectedCity(), custom.single);
  });

  testWidgets('time zones can be found by city or country', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpPage(tester, const LocationPage(),
        settings: await loadSettings(),
        cities: FakeCityRepository([City.berlin, tokyo, newYork]));
    await tester.tap(find.byTooltip('Add custom city'));
    await tester.pumpAndSettle();

    await tester.enterText(timeZoneField, 'japan');
    await tester.pumpAndSettle();
    expect(menuEntries(), ['Asia/Tokyo']);

    await tester.enterText(timeZoneField, 'new york');
    await tester.pumpAndSettle();
    expect(menuEntries(), ['America/New York']);

    await tester.enterText(timeZoneField, 'europe');
    await tester.pumpAndSettle();
    expect(menuEntries(), ['Europe/Berlin']);
  });

  testWidgets('flags can be found by country', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = FakeCityRepository([City.berlin, tokyo, newYork]);
    await pumpPage(tester, const LocationPage(),
        settings: await loadSettings(), cities: repository);
    await tester.tap(find.byTooltip('Add custom city'));
    await tester.pumpAndSettle();

    await tester.enterText(flagField, 'jap');
    await tester.pumpAndSettle();
    expect(menuEntries(), ['Japan']);
    await tester.tap(find.text('Japan').last);
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'City name'), 'Zuhause');
    await tester.enterText(timeZoneField, 'tokyo');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Asia/Tokyo').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    final custom = await repository.loadCustomCities();
    expect(custom.single.flag, 'jp.png');
  });

  testWidgets('deleting the selected custom city falls back to Berlin',
      (tester) async {
    const custom = City(
      name: 'Zuhause',
      country: '',
      timeZone: 'Asia/Tokyo',
      flag: '',
      utc: '+09:00',
      weatherZone: 'Zuhause',
      isCustom: true,
    );
    SharedPreferences.setMockInitialValues({
      CityRepository.customCitiesKey: jsonEncode([custom.toJson()]),
      CityRepository.selectedCityKey: jsonEncode(custom.toJson()),
    });
    final repository = FakeCityRepository();
    await pumpPage(tester, const LocationPage(),
        settings: await loadSettings(), cities: repository);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Zuhause'), findsNothing);
    expect(isSelected(tester, 'Berlin'), isTrue);
    expect(await repository.loadCustomCities(), isEmpty);
    expect(await repository.loadSelectedCity(), City.berlin);
  });
}
