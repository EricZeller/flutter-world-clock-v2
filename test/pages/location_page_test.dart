import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/pages/location/city_tile.dart';
import 'package:world_clock_v2/pages/location/location_page.dart';
import 'package:world_clock_v2/services/city_repository.dart';

import '../helpers/test_app.dart';

const newYork = City(
  name: 'New York',
  country: 'United States',
  timeZone: 'America/New_York',
  flag: 'us.webp',
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
  /// Whether the check box of [name] in the list of all cities is set.
  bool isFavorite(WidgetTester tester, String name) => tester
      .widget<CheckboxListTile>(find.ancestor(
        of: find.text(name).last,
        matching: find.byType(CheckboxListTile),
      ))
      .value!;

  List<String> favoriteNames(WidgetTester tester) => tester
      .widgetList<FavoriteTile>(find.byType(FavoriteTile))
      .map((tile) => tile.city.name)
      .toList();

  testWidgets('shows the stored city as favorite', (tester) async {
    SharedPreferences.setMockInitialValues({
      'selectedOption': jsonEncode(tokyo.toJson()),
    });

    await pumpPage(tester, const LocationPage(),
        settings: await loadSettings());

    expect(favoriteNames(tester), ['Tokyo']);
    expect(isFavorite(tester, 'Tokyo'), isTrue);
    expect(isFavorite(tester, 'Berlin'), isFalse);
  });

  testWidgets('checking cities adds and removes favorites', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = FakeCityRepository();
    await pumpPage(tester, const LocationPage(),
        settings: await loadSettings(), cities: repository);
    expect(favoriteNames(tester), ['Berlin']);

    await tester.tap(find.text('Tokyo').last);
    await tester.pumpAndSettle();
    expect(favoriteNames(tester), ['Berlin', 'Tokyo']);
    expect(await repository.loadFavorites(), [City.berlin, tokyo]);

    await tester.tap(find.text('Berlin').last);
    await tester.pumpAndSettle();
    expect(favoriteNames(tester), ['Tokyo']);
    expect(await repository.loadFavorites(), [tokyo]);
    expect(await repository.loadSelectedCity(), tokyo,
        reason: 'older versions read the first favorite');
  });

  testWidgets('the last city cannot be removed', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = FakeCityRepository();
    await pumpPage(tester, const LocationPage(),
        settings: await loadSettings(), cities: repository);

    await tester.tap(find.byTooltip('Remove'));
    await tester.pump();

    expect(find.text('At least one city must stay'), findsOneWidget);
    expect(favoriteNames(tester), ['Berlin']);
  });

  testWidgets('favorites can be removed and reordered', (tester) async {
    final repository = FakeCityRepository([City.berlin, tokyo, newYork]);
    SharedPreferences.setMockInitialValues({});
    await repository.saveFavorites([City.berlin, tokyo, newYork]);
    await pumpPage(tester, const LocationPage(),
        settings: await loadSettings(), cities: repository);

    await tester.tap(find.byTooltip('Remove').at(1));
    await tester.pumpAndSettle();
    expect(favoriteNames(tester), ['Berlin', 'New York']);

    final handle = find.byIcon(Icons.drag_handle).last;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(favoriteNames(tester), ['New York', 'Berlin']);
    expect(await repository.loadFavorites(), [newYork, City.berlin]);
  });

  group('the tapped city keeps its place', () {
    // Enough cities to scroll the favorites out of sight.
    final cities = [
      City.berlin,
      for (var i = 1; i <= 30; i++)
        City(
          name: 'City ${i.toString().padLeft(2, '0')}',
          country: 'Country',
          timeZone: 'Europe/Berlin',
          flag: '',
          utc: '+02:00',
          weatherZone: 'City $i',
        ),
    ];

    ScrollPosition listPosition(WidgetTester tester) => tester
        .state<ScrollableState>(find.descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        ))
        .position;

    Finder cityTile(String name) =>
        find.widgetWithText(CheckboxListTile, name);

    Future<FakeCityRepository> pumpCities(
        WidgetTester tester, List<City> favorites) async {
      SharedPreferences.setMockInitialValues({});
      final repository = FakeCityRepository(cities);
      await repository.saveFavorites(favorites);
      await pumpPage(tester, const LocationPage(),
          settings: await loadSettings(), cities: repository);
      return repository;
    }

    testWidgets('when it becomes a favorite', (tester) async {
      await pumpCities(tester, [City.berlin]);
      listPosition(tester).jumpTo(800);
      await tester.pumpAndSettle();
      final before = tester.getTopLeft(cityTile('City 15'));

      await tester.tap(cityTile('City 15'));
      await tester.pump();
      expect(tester.getTopLeft(cityTile('City 15')).dy,
          moreOrLessEquals(before.dy, epsilon: 1),
          reason: 'not even a single frame shows the shifted list');
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(cityTile('City 15')).dy,
          moreOrLessEquals(before.dy, epsilon: 1));
      expect(listPosition(tester).pixels, greaterThan(800));
      expect(favoriteNames(tester), isNot(contains('Berlin')),
          reason: 'the favorites are still out of sight');
      expect(isFavorite(tester, 'City 15'), isTrue);

      listPosition(tester).jumpTo(0);
      await tester.pumpAndSettle();
      expect(favoriteNames(tester), ['Berlin', 'City 15']);
    });

    testWidgets('when it is no favorite anymore', (tester) async {
      final repository = await pumpCities(
          tester, [City.berlin, cities[3], cities[20], cities[5]]);
      listPosition(tester).jumpTo(1500);
      await tester.pumpAndSettle();
      final before = tester.getTopLeft(cityTile('City 20'));

      await tester.tap(cityTile('City 20'));
      await tester.pump();
      expect(tester.getTopLeft(cityTile('City 20')).dy,
          moreOrLessEquals(before.dy, epsilon: 1));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(cityTile('City 20')).dy,
          moreOrLessEquals(before.dy, epsilon: 1));
      expect(listPosition(tester).pixels, lessThan(1500));
      expect(isFavorite(tester, 'City 20'), isFalse);
      expect(await repository.loadFavorites(),
          [City.berlin, cities[3], cities[5]]);
    });

    testWidgets('but not at the top of the list', (tester) async {
      await pumpCities(tester, [City.berlin]);
      expect(listPosition(tester).pixels, 0);
      final before = tester.getTopLeft(cityTile('City 03'));

      await tester.tap(cityTile('City 03'));
      await tester.pumpAndSettle();

      expect(listPosition(tester).pixels, 0);
      expect(favoriteNames(tester), ['Berlin', 'City 03'],
          reason: 'the new favorite is in sight');
      expect(tester.getTopLeft(cityTile('City 03')).dy, greaterThan(before.dy),
          reason: 'the new favorite pushes the list down');
    });
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

  testWidgets('adds a custom city to the favorites', (tester) async {
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

    expect(find.text('Zuhause'), findsNWidgets(2),
        reason: 'in the favorites and in the list');
    expect(isFavorite(tester, 'Zuhause'), isTrue);
    expect(favoriteNames(tester), ['Berlin', 'Zuhause']);
    final custom = await repository.loadCustomCities();
    expect(custom.single.name, 'Zuhause');
    expect(custom.single.timeZone, 'Asia/Tokyo');
    expect(custom.single.isCustom, isTrue);
    expect(await repository.loadFavorites(), [City.berlin, custom.single]);
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

    await tester.enterText(timeZoneField, 'America/New_York');
    await tester.pumpAndSettle();
    expect(menuEntries(), ['America/New York']);
  });

  testWidgets('a search without picking an entry clears the selection',
      (tester) async {
    const custom = City(
      name: 'Zuhause',
      country: '',
      timeZone: 'Asia/Tokyo',
      flag: 'jp.webp',
      utc: '+09:00',
      weatherZone: 'Zuhause',
      isCustom: true,
    );
    SharedPreferences.setMockInitialValues({
      CityRepository.customCitiesKey: jsonEncode([custom.toJson()]),
    });
    final repository = FakeCityRepository();
    await pumpPage(tester, const LocationPage(),
        settings: await loadSettings(), cities: repository);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    final addButton = find.widgetWithText(FilledButton, 'Add');
    expect(tester.widget<FilledButton>(addButton).onPressed, isNotNull);

    await tester.enterText(timeZoneField, 'berl');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(addButton).onPressed, isNull,
        reason: 'the typed text no longer names a time zone');

    await tester.tap(find.text('Europe/Berlin').last);
    await tester.pumpAndSettle();
    await tester.enterText(flagField, '');
    await tester.pumpAndSettle();
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    final saved = (await repository.loadCustomCities()).single;
    expect(saved.timeZone, 'Europe/Berlin');
    expect(saved.flag, isEmpty);
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
    expect(custom.single.flag, 'jp.webp');
  });

  testWidgets('editing a favorite custom city keeps its place',
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
    });
    final repository = FakeCityRepository();
    await repository.saveFavorites([custom, City.berlin]);
    await repository.saveWidgetCity(7, custom);
    await pumpPage(tester, const LocationPage(),
        settings: await loadSettings(), cities: repository);

    // Only the flag changes, so the city stays equal to the old one.
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(flagField, 'jap');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Japan').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(favoriteNames(tester), ['Zuhause', 'Berlin']);
    final favorites = await repository.loadFavorites();
    expect(favorites.first.flag, 'jp.webp');
    expect((await repository.loadWidgetCities())[7]!.flag, 'jp.webp',
        reason: 'the widget shows the edited city');
  });

  testWidgets('editing a custom city does not make it a favorite',
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
    });
    final repository = FakeCityRepository();
    await pumpPage(tester, const LocationPage(),
        settings: await loadSettings(), cities: repository);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(favoriteNames(tester), ['Berlin']);
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
    await repository.saveWidgetCity(7, custom);
    await repository.saveWidgetCity(9, tokyo);
    await pumpPage(tester, const LocationPage(),
        settings: await loadSettings(), cities: repository);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Zuhause'), findsNothing);
    expect(favoriteNames(tester), ['Berlin']);
    expect(await repository.loadCustomCities(), isEmpty);
    expect(await repository.loadFavorites(), [City.berlin]);
    expect(await repository.loadWidgetCities(), {9: tokyo},
        reason: 'widget 7 falls back to the first favorite');
  });
}
