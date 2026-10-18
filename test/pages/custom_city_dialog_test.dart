import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/pages/location/custom_city_dialog.dart';
import 'package:world_clock_v2/services/city_repository.dart';

import '../helpers/custom_city_dialog.dart';
import '../helpers/test_app.dart';

City bundled(
  String name,
  String country,
  String timeZone,
  String flag, {
  String utc = '+00:00',
  double? latitude,
  double? longitude,
}) =>
    City(
      name: name,
      country: country,
      timeZone: timeZone,
      flag: flag,
      utc: utc,
      weatherZone: name,
      latitude: latitude,
      longitude: longitude,
    );

City custom({
  String country = '',
  String flag = '',
  String timeZone = 'Asia/Tokyo',
}) =>
    City(
      name: 'Zuhause',
      country: country,
      timeZone: timeZone,
      flag: flag,
      utc: '+09:00',
      weatherZone: 'Zuhause',
      isCustom: true,
    );

final cities = [
  // Listed first and sharing the zone of Paris, so a city of France has to
  // be picked on purpose for the coordinates.
  bundled(
    'Monaco',
    'Monaco',
    'Europe/Paris',
    'mc.webp',
    utc: '+02:00',
    latitude: 43.73,
    longitude: 7.42,
  ),
  bundled(
    'Paris',
    'France',
    'Europe/Paris',
    'fr.webp',
    utc: '+02:00',
    latitude: 48.86,
    longitude: 2.35,
  ),
  City.berlin,
  tokyo,
  bundled(
    'New York',
    'United States',
    'America/New_York',
    'us.webp',
    utc: '-04:00',
  ),
  bundled(
    'Los Angeles',
    'United States',
    'America/Los_Angeles',
    'us.webp',
    utc: '-07:00',
  ),
  bundled(
    'Seattle',
    'United States',
    'America/Los_Angeles',
    'us.webp',
    utc: '-07:00',
  ),
  bundled('Beijing', 'China', 'Asia/Shanghai', 'cn.webp', utc: '+08:00'),
  bundled('Hong Kong', 'China', 'Asia/Hong_Kong', 'hk.webp', utc: '+08:00'),
  // Custom cities offer neither their country nor their coordinates.
  custom(country: 'Atlantis', flag: 'gr.webp', timeZone: 'Europe/Athens'),
];

/// What the dialog returned, once it is closed.
class DialogResult {
  bool closed = false;
  City? city;
}

Future<DialogResult> openDialog(WidgetTester tester,
    {City? editing, List<City>? from}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  final result = DialogResult();
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              result.city = await showCustomCityDialog(
                context,
                cities: from ?? cities,
                editing: editing,
              );
              result.closed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  bool canSave(WidgetTester tester) =>
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Add'))
          .onPressed !=
      null;

  String fieldText(WidgetTester tester, Finder field) =>
      tester.widget<TextField>(field).controller!.text;

  bool timeZoneEnabled(WidgetTester tester) => tester
      .widget<DropdownMenu<String>>(dropdownMenu('IANA time zone'))
      .enabled;

  Future<void> enterName(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextField, 'City name'),
      'Zuhause',
    );
    await tester.pump();
  }

  testWidgets('countries can be found by name or city', (tester) async {
    await openDialog(tester);

    await tester.enterText(countryField, 'states');
    await tester.pumpAndSettle();
    expect(menuEntries(), ['United States']);

    await tester.enterText(countryField, 'seattle');
    await tester.pumpAndSettle();
    expect(menuEntries(), ['United States']);

    await tester.enterText(countryField, 'china');
    await tester.pumpAndSettle();
    expect(
        menuEntries(),
        [
          'China (Beijing)',
          'China (Hong Kong)',
        ],
        reason: 'two flags share the name, so their cities tell them apart');

    await tester.enterText(countryField, 'atlantis');
    await tester.pumpAndSettle();
    expect(menuEntries(), isEmpty, reason: 'custom cities offer no country');
  });

  testWidgets('the bundled countries can be told apart', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final bundledCities =
        await tester.runAsync(() => CityRepository().loadAllCities());
    await openDialog(tester, from: bundledCities);

    await tester.enterText(countryField, 'china');
    await tester.pumpAndSettle();
    expect(menuEntries(), ['China (Beijing)', 'China (Hong Kong)']);

    await pickCountry(tester, 'united states', 'United States');
    await tester.tap(timeZoneField);
    await tester.pumpAndSettle();
    expect(menuEntries(), [
      'America/Chicago',
      'America/Los Angeles',
      'America/New York',
      'Pacific/Honolulu',
    ]);
  });

  testWidgets('the time zone needs a country first', (tester) async {
    await openDialog(tester);
    await enterName(tester);

    expect(timeZoneEnabled(tester), isFalse);
    expect(find.text('Pick a country first'), findsOneWidget);
    expect(canSave(tester), isFalse);
  });

  testWidgets('a country offers only its own time zones', (tester) async {
    await openDialog(tester);
    await pickCountry(tester, 'united', 'United States');

    expect(timeZoneEnabled(tester), isTrue);
    expect(find.text('Pick a country first'), findsNothing);
    expect(
      fieldText(tester, timeZoneField),
      isEmpty,
      reason: 'the country has more than one zone',
    );
    await tester.tap(timeZoneField);
    await tester.pumpAndSettle();
    expect(menuEntries(), ['America/Los Angeles', 'America/New York']);

    await tester.enterText(timeZoneField, 'seattle');
    await tester.pumpAndSettle();
    expect(
        menuEntries(),
        [
          'America/Los Angeles',
        ],
        reason: 'zones can still be found by their cities');

    await tester.enterText(timeZoneField, 'tokyo');
    await tester.pumpAndSettle();
    expect(menuEntries(), isEmpty);
  });

  testWidgets('a country with one time zone picks it', (tester) async {
    await openDialog(tester);
    await enterName(tester);
    await pickCountry(tester, 'jap', 'Japan');

    expect(fieldText(tester, timeZoneField), 'Asia/Tokyo');
    expect(canSave(tester), isTrue);
  });

  testWidgets('changing the country clears a time zone that does not fit', (
    tester,
  ) async {
    await openDialog(tester);
    await enterName(tester);
    await pickCountry(tester, 'united', 'United States');
    await pickTimeZone(tester, 'new', 'America/New York');
    expect(canSave(tester), isTrue);

    await pickCountry(tester, 'hong', 'China (Hong Kong)');
    expect(fieldText(tester, timeZoneField), 'Asia/Hong Kong');

    await pickCountry(tester, 'united', 'United States');
    expect(fieldText(tester, timeZoneField), isEmpty);
    expect(canSave(tester), isFalse);
  });

  testWidgets('saving needs a name, a country and a time zone of it', (
    tester,
  ) async {
    await openDialog(tester);
    expect(canSave(tester), isFalse);

    await pickCountry(tester, 'united', 'United States');
    await pickTimeZone(tester, 'los', 'America/Los Angeles');
    expect(canSave(tester), isFalse, reason: 'the name is missing');

    await enterName(tester);
    expect(canSave(tester), isTrue);

    await tester.enterText(timeZoneField, 'new');
    await tester.pumpAndSettle();
    expect(
      canSave(tester),
      isFalse,
      reason: 'the typed text no longer names a time zone',
    );
    await tester.tap(find.text('America/New York').last);
    await tester.pumpAndSettle();
    expect(canSave(tester), isTrue);

    await tester.enterText(countryField, 'fra');
    await tester.pumpAndSettle();
    expect(
      canSave(tester),
      isFalse,
      reason: 'the typed text no longer names a country',
    );
    expect(timeZoneEnabled(tester), isFalse);
  });

  testWidgets('saves the picked country with its flag and its own city data', (
    tester,
  ) async {
    final result = await openDialog(tester);
    await enterName(tester);
    await pickCountry(tester, 'fra', 'France');
    expect(fieldText(tester, timeZoneField), 'Europe/Paris');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(result.closed, isTrue);
    final city = result.city!;
    expect(city.name, 'Zuhause');
    expect(city.country, 'France');
    expect(city.flag, 'fr.webp');
    expect(city.timeZone, 'Europe/Paris');
    expect(city.utc, '+02:00');
    expect(
      (city.latitude, city.longitude),
      (48.86, 2.35),
      reason: 'from Paris, not from Monaco in the same zone',
    );
    expect(city.isCustom, isTrue);
  });

  group('editing a city of an older version', () {
    testWidgets('keeps a matching country and time zone', (tester) async {
      final result = await openDialog(
        tester,
        editing: custom(country: 'Japan', flag: 'jp.webp'),
      );

      expect(fieldText(tester, countryField), 'Japan');
      expect(fieldText(tester, timeZoneField), 'Asia/Tokyo');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(result.city!.country, 'Japan');
      expect(result.city!.flag, 'jp.webp');
      expect(result.city!.timeZone, 'Asia/Tokyo');
    });

    testWidgets('without country takes the only country of its zone', (
      tester,
    ) async {
      final result = await openDialog(tester, editing: custom());

      expect(fieldText(tester, countryField), 'Japan');
      expect(canSave(tester), isTrue);
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(result.city!.country, 'Japan');
      expect(result.city!.flag, 'jp.webp');
    });

    testWidgets('with a flag of no country takes the only country of its zone',
        (tester) async {
      final result = await openDialog(
        tester,
        editing: custom(flag: 'xx.webp'),
      );

      expect(fieldText(tester, countryField), 'Japan');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(result.city!.country, 'Japan');
      expect(result.city!.flag, 'jp.webp');
    });

    testWidgets('saves a typed country name as the one of its flag', (
      tester,
    ) async {
      final result = await openDialog(
        tester,
        editing: custom(
          country: 'Deutschland',
          flag: 'de.webp',
          timeZone: 'Europe/Berlin',
        ),
      );

      expect(fieldText(tester, countryField), 'Germany');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(result.city!.country, 'Germany');
      expect(result.city!.flag, 'de.webp');
      expect(result.city!.timeZone, 'Europe/Berlin');
    });

    testWidgets('prefers the flag or name whose country has the zone', (
      tester,
    ) async {
      final result = await openDialog(
        tester,
        editing: custom(
          country: 'United States',
          flag: 'jp.webp',
          timeZone: 'America/New_York',
        ),
      );

      expect(fieldText(tester, countryField), 'United States');
      expect(fieldText(tester, timeZoneField), 'America/New York');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(result.city!.country, 'United States');
      expect(result.city!.flag, 'us.webp');
    });

    testWidgets('shows a time zone of another country until it is fixed', (
      tester,
    ) async {
      final result = await openDialog(
        tester,
        editing: custom(
          country: 'Germany',
          flag: 'jp.webp',
          timeZone: 'America/New_York',
        ),
      );

      expect(
        fieldText(tester, countryField),
        'Japan',
        reason: 'neither has the zone, so the flag wins',
      );
      expect(fieldText(tester, timeZoneField), 'America/New York');
      expect(find.text('Not a time zone of this country'), findsOneWidget);
      expect(canSave(tester), isFalse);

      await tester.tap(timeZoneField);
      await tester.pumpAndSettle();
      expect(menuEntries(), ['Asia/Tokyo']);
      await tester.tap(find.text('Asia/Tokyo').last);
      await tester.pumpAndSettle();
      expect(find.text('Not a time zone of this country'), findsNothing);
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(result.city!.country, 'Japan');
      expect(result.city!.timeZone, 'Asia/Tokyo');
    });

    testWidgets('shows an unknown country until one of the list is picked', (
      tester,
    ) async {
      final result = await openDialog(
        tester,
        editing: custom(country: 'Atlantis', timeZone: 'Asia/Tokyo'),
      );

      expect(fieldText(tester, countryField), 'Atlantis');
      expect(find.text('Pick a country from the list'), findsOneWidget);
      expect(fieldText(tester, timeZoneField), 'Asia/Tokyo');
      expect(timeZoneEnabled(tester), isFalse);
      expect(canSave(tester), isFalse);

      await pickCountry(tester, 'jap', 'Japan');
      expect(find.text('Pick a country from the list'), findsNothing);
      expect(fieldText(tester, timeZoneField), 'Asia/Tokyo');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(result.city!.country, 'Japan');
      expect(result.city!.flag, 'jp.webp');
    });
  });
}
