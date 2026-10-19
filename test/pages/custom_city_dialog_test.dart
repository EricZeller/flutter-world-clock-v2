import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/models/country_zone.dart';
import 'package:world_clock_v2/pages/location/custom_city_dialog.dart';
import 'package:world_clock_v2/services/city_repository.dart';

import '../helpers/custom_city_dialog.dart';
import '../helpers/test_app.dart';
import '../helpers/time_zones.dart';

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

Future<DialogResult> openDialog(
  WidgetTester tester, {
  City? editing,
  List<City>? from,
  Map<String, List<CountryZone>> countryZones = const {},
  Size physicalSize = const Size(1080, 2400),
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  final result = DialogResult();
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              result.city = await showCustomCityDialog(
                context,
                cities: from ?? cities,
                countryZones: countryZones,
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

  group('in German', () {
    final germanCountryField = find.descendant(
      of: dropdownMenu('Land'),
      matching: find.byType(TextField),
    );

    Future<void> search(WidgetTester tester, String query) async {
      await tester.enterText(germanCountryField, query);
      await tester.pumpAndSettle();
    }

    testWidgets('the countries are labeled and found in German', (
      tester,
    ) async {
      await openDialog(tester, locale: const Locale('de'));

      await search(tester, 'vereinigte');
      expect(menuEntries(), ['Vereinigte Staaten']);
      await search(tester, 'states');
      expect(menuEntries(), ['Vereinigte Staaten'],
          reason: 'the English name is found as well');
      await search(tester, 'frankreich');
      expect(menuEntries(), ['Frankreich']);
      await search(tester, 'china');
      expect(menuEntries(), ['China (Beijing)', 'China (Hong Kong)']);
      await search(tester, 'peking');
      expect(menuEntries(), ['China (Beijing)'],
          reason: 'cities are found by their German names');
      await search(tester, 'Hongkong');
      expect(menuEntries(), ['China (Hong Kong)']);
    });

    testWidgets('the cities keep the English country', (tester) async {
      final result = await openDialog(tester, locale: const Locale('de'));
      await tester.enterText(
        find.widgetWithText(TextField, 'Stadtname'),
        'Zuhause',
      );
      await search(tester, 'deutsch');
      await tester.tap(find.text('Deutschland').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hinzufügen'));
      await tester.pumpAndSettle();

      expect(result.city!.country, 'Germany');
      expect(result.city!.flag, 'de.webp');
    });

    testWidgets('a city entered in German finds its country', (
      tester,
    ) async {
      await openDialog(
        tester,
        locale: const Locale('de'),
        editing: custom(country: 'Frankreich', timeZone: 'Europe/Paris'),
      );

      expect(fieldText(tester, germanCountryField), 'Frankreich');
      expect(find.text('Wähle ein Land aus der Liste'), findsNothing);
    });

    testWidgets('a new app language relabels the picked country', (
      tester,
    ) async {
      final locale = ValueNotifier(const Locale('en'));
      addTearDown(locale.dispose);
      await tester.pumpWidget(
        ValueListenableBuilder(
          valueListenable: locale,
          builder: (context, value, _) => MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: value,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () =>
                      showCustomCityDialog(context, cities: cities),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await pickCountry(tester, 'germ', 'Germany');

      locale.value = const Locale('de');
      await tester.pumpAndSettle();

      expect(fieldText(tester, germanCountryField), 'Deutschland');
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Hinzufügen'),
            )
            .onPressed,
        isNull,
        reason: 'no name yet, but the country stays picked',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Stadtname'),
        'Zuhause',
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Hinzufügen'),
            )
            .onPressed,
        isNotNull,
        reason: 'the country and its only zone are still picked',
      );
    });

    testWidgets('French labels China and Hong Kong apart', (tester) async {
      await openDialog(tester, locale: const Locale('fr'));

      await tester.enterText(
        find.descendant(
          of: dropdownMenu('Pays'),
          matching: find.byType(TextField),
        ),
        'chine',
      );
      await tester.pumpAndSettle();
      expect(menuEntries(), ['Chine (Beijing)', 'Chine (Hong Kong)']);
    });
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

  group('with the time zones of the tz database', () {
    setUpAll(initializeAppTimeZones);

    final countryZones = CountryZone.parseAll(
        File(CityRepository.countryZonesAsset).readAsStringSync());

    Future<DialogResult> openBundled(WidgetTester tester,
        {City? editing, Size physicalSize = const Size(1080, 2400)}) async {
      SharedPreferences.setMockInitialValues({});
      final bundledCities =
          await tester.runAsync(() => CityRepository().loadAllCities());
      return openDialog(
        tester,
        editing: editing,
        from: bundledCities,
        countryZones: countryZones,
        physicalSize: physicalSize,
      );
    }

    Future<List<String>> searchTimeZones(
        WidgetTester tester, String query) async {
      await tester.enterText(timeZoneField, query);
      await tester.pumpAndSettle();
      return menuEntries();
    }

    testWidgets('a country offers all its zones, not only its cities\'',
        (tester) async {
      await openBundled(tester);
      await pickCountry(tester, 'canada', 'Canada');

      expect(fieldText(tester, timeZoneField), 'America/Toronto',
          reason: 'the zone of its bundled cities');
      expect(await searchTimeZones(tester, 'vancouver'), ['America/Vancouver']);
      expect(find.text('MST - BC (most areas)'), findsOneWidget,
          reason: 'the zone tells where it applies');
      expect(await searchTimeZones(tester, 'toronto'), ['America/Toronto']);
      expect(await searchTimeZones(tester, 'america/st_j'),
          ['America/St Johns']);
      expect(await searchTimeZones(tester, 'los angeles'), isEmpty);

      await pickCountry(tester, 'australia', 'Australia');
      expect(await searchTimeZones(tester, 'perth'), ['Australia/Perth']);
      expect(await searchTimeZones(tester, 'sydney'), ['Australia/Sydney']);

      await pickCountry(tester, 'russia', 'Russia');
      expect(await searchTimeZones(tester, 'novosibirsk'),
          ['Asia/Novosibirsk']);
    });

    testWidgets('zones are sorted and can be found by where they apply',
        (tester) async {
      await openBundled(tester);
      await pickCountry(tester, 'canada', 'Canada');

      expect(await searchTimeZones(tester, 'bc'), [
        'America/Creston',
        'America/Edmonton',
        'America/Fort Nelson',
        'America/Vancouver',
      ]);
      expect(await searchTimeZones(tester, 'mst bc most'),
          ['America/Vancouver']);

      await pickCountry(tester, 'united states', 'United States');
      expect(
          await searchTimeZones(tester, 'seattle'), ['America/Los Angeles'],
          reason: 'zones can still be found by their cities');
      expect(
        await searchTimeZones(tester, 'alaska'),
        contains('America/Anchorage'),
      );
    });

    testWidgets('a country with a single zone still picks it', (tester) async {
      await openBundled(tester);
      await pickCountry(tester, 'japan', 'Japan');
      expect(fieldText(tester, timeZoneField), 'Asia/Tokyo');

      await pickCountry(tester, 'hong', 'China (Hong Kong)');
      expect(fieldText(tester, timeZoneField), 'Asia/Hong Kong');

      await pickCountry(tester, 'kosovo', 'Kosovo');
      expect(fieldText(tester, timeZoneField), 'Europe/Belgrade',
          reason: 'without zones in the tz database, those of its city');
    });

    testWidgets('the zone of the bundled cities is preselected', (
      tester,
    ) async {
      await openBundled(tester);
      await enterName(tester);
      await pickCountry(tester, 'germany', 'Germany');

      expect(fieldText(tester, timeZoneField), 'Europe/Berlin');
      expect(canSave(tester), isTrue);

      await pickCountry(tester, 'spain', 'Spain');
      expect(fieldText(tester, timeZoneField), 'Europe/Madrid');
      expect(find.text('Spain (mainland)'), findsOneWidget,
          reason: 'the picked zone tells where it applies');
      await tester.tap(timeZoneField);
      await tester.pumpAndSettle();
      expect(
          menuEntries(), ['Africa/Ceuta', 'Atlantic/Canary', 'Europe/Madrid'],
          reason: 'the other zones are still offered');
      await tester.tap(find.text('Africa/Ceuta').last);
      await tester.pumpAndSettle();
      expect(fieldText(tester, timeZoneField), 'Africa/Ceuta');
      expect(find.text('Spain (mainland)'), findsNothing);

      await pickCountry(tester, 'united states', 'United States');
      expect(fieldText(tester, timeZoneField), isEmpty,
          reason: 'its bundled cities have several zones');
      expect(canSave(tester), isFalse);
    });

    testWidgets('Germany offers only Europe/Berlin', (tester) async {
      await openBundled(tester);
      await pickCountry(tester, 'germany', 'Germany');

      await tester.tap(timeZoneField);
      await tester.pumpAndSettle();
      expect(menuEntries(), ['Europe/Berlin'],
          reason: 'Busingen has had the time of Berlin since 1981');
      expect(find.text('most of Germany'), findsNothing,
          reason: 'the only zone of a country needs no comment');
      expect(find.text('Busingen'), findsNothing);
    });

    testWidgets('a zone with the time of another is found as that one', (
      tester,
    ) async {
      await openBundled(tester);
      await pickCountry(tester, 'germany', 'Germany');
      expect(await searchTimeZones(tester, 'busingen'), ['Europe/Berlin']);

      await pickCountry(tester, 'united states', 'United States');
      expect(await searchTimeZones(tester, 'detroit'), ['America/New York']);
      expect(await searchTimeZones(tester, 'boise'), ['America/Denver']);

      await pickCountry(tester, 'canada', 'Canada');
      expect(await searchTimeZones(tester, 'dawson cr'), ['America/Creston']);
    });

    testWidgets('a city saved with Europe/Busingen gets Europe/Berlin', (
      tester,
    ) async {
      final result = await openBundled(
        tester,
        editing: const City(
          name: 'Büsingen',
          country: 'Germany',
          timeZone: 'Europe/Busingen',
          flag: 'de.webp',
          utc: '+02:00',
          weatherZone: 'Büsingen',
          latitude: 47.7,
          longitude: 8.6833,
          isCustom: true,
        ),
      );

      expect(fieldText(tester, countryField), 'Germany');
      expect(fieldText(tester, timeZoneField), 'Europe/Berlin');
      expect(find.text('Not a time zone of this country'), findsNothing);
      expect(canSave(tester), isTrue);
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(result.city!.name, 'Büsingen');
      expect(result.city!.country, 'Germany');
      expect(result.city!.timeZone, 'Europe/Berlin');
    });

    testWidgets('a zone with the time of another finds its country', (
      tester,
    ) async {
      await openBundled(
        tester,
        editing: custom(timeZone: 'America/Detroit'),
      );

      expect(fieldText(tester, countryField), 'United States');
      expect(fieldText(tester, timeZoneField), 'America/New York');

      await pickCountry(tester, 'canada', 'Canada');
      expect(fieldText(tester, timeZoneField), 'America/Toronto',
          reason: 'Detroit is no zone of Canada');
    });

    testWidgets('long lists of zones fit on a small phone', (tester) async {
      // 320 x 568 like an iPhone SE (1st generation).
      await openBundled(tester, physicalSize: const Size(640, 1136));
      await enterName(tester);

      await pickCountry(tester, 'indonesia', 'Indonesia');
      await pickTimeZone(tester, 'bali', 'Asia/Makassar');
      expect(
        find.text('Borneo (east, south), Sulawesi/Celebes, Bali, '
            'Nusa Tengarra, Timor (west)'),
        findsOneWidget,
      );

      await pickCountry(tester, 'russia', 'Russia');
      await tester.tap(timeZoneField);
      await tester.pumpAndSettle();
      expect(menuEntries(), isNotEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an alias zone of a city is offered once', (tester) async {
      await openBundled(tester);
      await pickCountry(tester, 'ukraine', 'Ukraine');

      await tester.tap(timeZoneField);
      await tester.pumpAndSettle();
      expect(menuEntries(), ['Europe/Kiev', 'Europe/Simferopol']);
      expect(await searchTimeZones(tester, 'kyiv'), ['Europe/Kiev']);
    });

    testWidgets('a zone without a bundled city saves its own location', (
      tester,
    ) async {
      final result = await openBundled(tester);
      await enterName(tester);
      await pickCountry(tester, 'canada', 'Canada');
      await pickTimeZone(tester, 'vancouver', 'America/Vancouver');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      final city = result.city!;
      expect(city.country, 'Canada');
      expect(city.flag, 'ca.webp');
      expect(city.timeZone, 'America/Vancouver');
      expect(city.utc, '-07:00', reason: 'as listed in summer, like Seattle');
      expect(city.latitude, closeTo(49.2667, 0.0001));
      expect(city.longitude, closeTo(-123.1167, 0.0001));
      expect(city.weatherZone, 'Zuhause');
      expect(city.isCustom, isTrue);
    });

    testWidgets('a zone without a bundled city saves its offset', (
      tester,
    ) async {
      final result = await openBundled(tester);
      await enterName(tester);
      await pickCountry(tester, 'australia', 'Australia');
      await pickTimeZone(tester, 'perth', 'Australia/Perth');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(result.city!.utc, '+08:00');
      expect(result.city!.latitude, closeTo(-31.95, 0.01));
    });

    testWidgets('a zone with a bundled city keeps saving its data', (
      tester,
    ) async {
      final result = await openBundled(tester);
      await enterName(tester);
      await pickCountry(tester, 'canada', 'Canada');
      await pickTimeZone(tester, 'toronto', 'America/Toronto');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(result.city!.timeZone, 'America/Toronto');
      expect(result.city!.utc, '-04:00');
      expect(result.city!.latitude, isNull, reason: 'as Toronto has none');
    });

    testWidgets('a city of an older version gets the zone of its country', (
      tester,
    ) async {
      final result = await openBundled(
        tester,
        editing: const City(
          name: 'Vancouver',
          country: 'Canada',
          timeZone: 'America/Los_Angeles',
          flag: 'ca.webp',
          utc: '-07:00',
          weatherZone: 'Vancouver',
          isCustom: true,
        ),
      );

      expect(fieldText(tester, countryField), 'Canada');
      expect(fieldText(tester, timeZoneField), 'America/Los Angeles');
      expect(find.text('Not a time zone of this country'), findsOneWidget);
      expect(canSave(tester), isFalse);

      await pickTimeZone(tester, 'vancouver', 'America/Vancouver');
      expect(find.text('Not a time zone of this country'), findsNothing);
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      final city = result.city!;
      expect(city.name, 'Vancouver');
      expect(city.country, 'Canada');
      expect(city.timeZone, 'America/Vancouver');
      expect(city.utc, '-07:00');
      expect(city.latitude, closeTo(49.27, 0.01));
    });

    testWidgets('a city of an older version keeps a zone that now fits', (
      tester,
    ) async {
      await openBundled(
        tester,
        editing: const City(
          name: 'Perth',
          country: 'Australia',
          timeZone: 'Australia/Perth',
          flag: 'au.webp',
          utc: '+08:00',
          weatherZone: 'Perth',
          isCustom: true,
        ),
      );

      expect(fieldText(tester, countryField), 'Australia');
      expect(fieldText(tester, timeZoneField), 'Australia/Perth');
      expect(find.text('Not a time zone of this country'), findsNothing);
      expect(canSave(tester), isTrue);
    });
  });
}
