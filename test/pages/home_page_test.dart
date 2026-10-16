import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/pages/home/forecast_sheet.dart';
import 'package:world_clock_v2/pages/home/home_page.dart';
import 'package:world_clock_v2/services/city_repository.dart';

import '../helpers/fake_wttr.dart';
import '../helpers/home_widget_recorder.dart';
import '../helpers/test_app.dart';
import '../helpers/time_zones.dart';

void main() {
  setUpAll(initializeAppTimeZones);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows Berlin and its weather when nothing is selected',
      (tester) async {
    final wttr = FakeWttr();

    await pumpPage(tester, const HomePage(),
        settings: await loadSettings(), weather: wttr.service);

    expect(find.text('Berlin'), findsOneWidget);
    expect(find.text('Germany, UTC+02:00'), findsOneWidget);
    expect(find.text('☁️ Cloudy +20°C'), findsOneWidget);
    expect(wttr.requests.single.path, '/Berlin');
    expect(wttr.requests.single.queryParameters, {'format': 'j1'});
  });

  testWidgets('shows the stored city', (tester) async {
    SharedPreferences.setMockInitialValues({
      'selectedOption': jsonEncode(tokyo.toJson()),
    });
    final wttr = FakeWttr();

    await pumpPage(tester, const HomePage(),
        settings: await loadSettings(), weather: wttr.service);

    expect(find.text('Tokyo'), findsOneWidget);
    expect(find.text('Japan, UTC+09:00'), findsOneWidget);
    expect(wttr.requests.single.path, '/Tokyo');
  });

  testWidgets('shows sunrise and sunset with the extra info',
      (tester) async {
    await pumpPage(tester, const HomePage(), settings: await loadSettings());

    expect(find.text('07:11'), findsOneWidget);
    expect(find.text('18:39'), findsOneWidget);
  });

  testWidgets('hides extra info when disabled', (tester) async {
    SharedPreferences.setMockInitialValues({'spMoreInfo': false});

    await pumpPage(tester, const HomePage(), settings: await loadSettings());

    expect(find.text('Germany, UTC+02:00'), findsNothing);
    expect(find.byIcon(Icons.schedule_rounded), findsNothing);
    expect(find.text('07:11'), findsNothing);
  });

  testWidgets('uses Fahrenheit and 12h times when configured',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'useFahrenheit': true, 'use24hr': false});

    await pumpPage(tester, const HomePage(), settings: await loadSettings());

    expect(find.text('☁️ Cloudy +68°F'), findsOneWidget);
    expect(find.text('06:39 PM'), findsOneWidget);
  });

  testWidgets('requests translated weather for the app language',
      (tester) async {
    final wttr = FakeWttr();

    await pumpPage(tester, const HomePage(),
        settings: await loadSettings(),
        weather: wttr.service,
        locale: const Locale('de'));

    expect(wttr.requests.single.queryParameters['lang'], 'de');
    expect(find.text('☁️ Wolkig +20°C'), findsOneWidget);
  });

  testWidgets('shows a loading text until weather arrives', (tester) async {
    final wttr = FakeWttr()..hold = Completer();

    await pumpPage(tester, const HomePage(),
        settings: await loadSettings(), weather: wttr.service);

    expect(find.text('🛰️ Loading...'), findsOneWidget);
    wttr.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.text('☁️ Cloudy +20°C'), findsOneWidget);
  });

  testWidgets('shows recent cached weather without downloading',
      (tester) async {
    final wttr = FakeWttr();
    await wttr.service.refresh(server: 'https://wttr.in', zone: 'Berlin');

    await pumpPage(tester, const HomePage(),
        settings: await loadSettings(), weather: wttr.service);

    expect(find.text('☁️ Cloudy +20°C'), findsOneWidget);
    expect(wttr.requests, hasLength(1), reason: 'only the seeding request');
  });

  testWidgets('shows outdated cached weather while offline', (tester) async {
    final hourAgo = DateTime.now().subtract(const Duration(hours: 1));
    await FakeWttr(clock: () => hourAgo)
        .service
        .refresh(server: 'https://wttr.in', zone: 'Berlin');
    final wttr = FakeWttr(offline: true);

    await pumpPage(tester, const HomePage(),
        settings: await loadSettings(), weather: wttr.service);

    expect(find.text('☁️ Cloudy +20°C'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    expect(find.textContaining('Last updated'), findsOneWidget);
  });

  testWidgets('shows a connection error without cached weather',
      (tester) async {
    await pumpPage(tester, const HomePage(),
        settings: await loadSettings(),
        weather: FakeWttr(offline: true).service);

    expect(find.text('🛜 Connection error'), findsOneWidget);
  });

  testWidgets('shows an API error when wttr.in rejects the city',
      (tester) async {
    await pumpPage(tester, const HomePage(),
        settings: await loadSettings(),
        weather: FakeWttr(statusCode: 500).service);

    expect(find.text("🛜 Couldn't connect to API"), findsOneWidget);
  });

  testWidgets('recovers when the connection comes back', (tester) async {
    final wttr = FakeWttr(offline: true);
    await pumpPage(tester, const HomePage(),
        settings: await loadSettings(), weather: wttr.service);
    expect(find.text('🛜 Connection error'), findsOneWidget);

    wttr.offline = false;
    await tester.fling(
        find.byType(SingleChildScrollView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(find.text('☁️ Cloudy +20°C'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_rounded), findsNothing);
    expect(wttr.requests, hasLength(2));
  });

  testWidgets('tapping the weather opens the forecast', (tester) async {
    await pumpPage(tester, const HomePage(), settings: await loadSettings());

    await tester.tap(find.text('☁️ Cloudy +20°C'));
    await tester.pumpAndSettle();

    expect(find.byType(ForecastSheet), findsOneWidget);
    expect(find.text('Feels like +20°C'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('5 km/h'), findsOneWidget);
    expect(find.text('3-day forecast'), findsOneWidget);
    expect(find.text('15° / 20°'), findsOneWidget);
    expect(find.text('13° / 22°'), findsOneWidget);
  });

  testWidgets('weather is not tappable before it loaded', (tester) async {
    await pumpPage(tester, const HomePage(),
        settings: await loadSettings(),
        weather: FakeWttr(offline: true).service);

    await tester.tap(find.text('🛜 Connection error'));
    await tester.pumpAndSettle();

    expect(find.byType(ForecastSheet), findsNothing);
  });

  testWidgets('reloads the weather after returning from settings',
      (tester) async {
    final wttr = FakeWttr();
    await pumpPage(tester, const HomePage(),
        settings: await loadSettings(), weather: wttr.service);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('settings route'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    expect(wttr.requests, hasLength(2));
  });

  group('home screen widget', () {
    // Each widget update waits briefly before refreshing the widget.
    Future<void> flushWidgetUpdates(WidgetTester tester) =>
        tester.pump(const Duration(seconds: 2));

    testWidgets('only receives the stored city, never the default',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'selectedOption': jsonEncode(tokyo.toJson()),
      });
      final widget = HomeWidgetRecorder.install();

      await pumpPage(tester, const HomePage(), settings: await loadSettings());
      await flushWidgetUpdates(tester);

      expect(widget.valuesOf('city'), isNotEmpty);
      expect(widget.valuesOf('city'), everyElement('Tokyo'));
      expect(widget.valuesOf('timeZone'), everyElement('Asia/Tokyo'));
      expect(widget.current['weather'], '☁️ Cloudy +20°C');
      expect(widget.current['weather_icon'], '☁️');
      expect(widget.current['weather_temp'], '20°');
    });

    testWidgets('does not keep the weather of the previous city',
        (tester) async {
      final wttr = FakeWttr();
      final widget = HomeWidgetRecorder.install();
      await pumpPage(tester, const HomePage(),
          settings: await loadSettings(), weather: wttr.service);
      await flushWidgetUpdates(tester);
      expect(widget.current['weather'], '☁️ Cloudy +20°C');

      // Switch to a city without cached weather while offline.
      wttr.offline = true;
      await tester.tap(find.text('Manage cities'));
      await tester.pumpAndSettle();
      await CityRepository().saveFavorites([tokyo]);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      await flushWidgetUpdates(tester);

      expect(find.text('🛜 Connection error'), findsOneWidget);
      expect(widget.current['city'], 'Tokyo');
      expect(widget.current['weather'], '🛜 Connection error');
      expect(widget.current['weather_icon'], '🛜');
      expect(widget.current['weather_temp'], '');
    });
  });

  group('weather requests', () {
    testWidgets('a changed server is not answered by a running request',
        (tester) async {
      final wttr = FakeWttr()..hold = Completer();
      final settings = await loadSettings();
      await pumpPage(tester, const HomePage(),
          settings: settings, weather: wttr.service);
      expect(wttr.requests, hasLength(1));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await settings.setWttrServer('https://example.org');
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      expect(wttr.requests, hasLength(2));
      expect(wttr.requests.last.host, 'example.org');
      wttr.hold!.complete();
      await tester.pumpAndSettle();
      expect(find.text('☁️ Cloudy +20°C'), findsOneWidget);
    });

    testWidgets('a language change while loading requests translations',
        (tester) async {
      final wttr = FakeWttr()..hold = Completer();
      final settings = await loadSettings();
      await pumpPage(tester, const HomePage(),
          settings: settings, weather: wttr.service);

      await pumpPage(tester, const HomePage(),
          settings: settings,
          weather: wttr.service,
          locale: const Locale('de'));
      wttr.hold!.complete();
      await tester.pumpAndSettle();

      expect(wttr.requests, hasLength(2));
      expect(wttr.requests.last.queryParameters['lang'], 'de');
      expect(find.text('☁️ Wolkig +20°C'), findsOneWidget);
    });

    testWidgets('an older answer does not overwrite a newer one',
        (tester) async {
      final wttr = FakeWttr()..hold = Completer();
      final settings = await loadSettings();
      await pumpPage(tester, const HomePage(),
          settings: settings, weather: wttr.service);
      final englishRequest = wttr.hold!;

      // The German request answers first, the English one afterwards.
      wttr.hold = null;
      await pumpPage(tester, const HomePage(),
          settings: settings,
          weather: wttr.service,
          locale: const Locale('de'));
      expect(find.text('☁️ Wolkig +20°C'), findsOneWidget);
      englishRequest.complete();
      await tester.pumpAndSettle();

      expect(find.text('☁️ Wolkig +20°C'), findsOneWidget);
    });
  });

  group('multiple cities', () {
    const newYork = City(
      name: 'New York',
      country: 'United States',
      timeZone: 'America/New_York',
      flag: 'us.png',
      utc: '-04:00',
      weatherZone: 'New York',
    );

    Future<void> storeFavorites(List<City> favorites, {int index = 0}) async {
      SharedPreferences.setMockInitialValues({
        CityRepository.favoritesKey:
            jsonEncode(favorites.map((city) => city.toJson()).toList()),
        CityRepository.currentIndexKey: index,
      });
    }

    testWidgets('migrates the single city of older versions', (tester) async {
      SharedPreferences.setMockInitialValues({
        'selectedOption': jsonEncode(tokyo.toJson()),
      });

      await pumpPage(tester, const HomePage(), settings: await loadSettings());

      expect(find.text('Tokyo'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('City 1 of')), findsNothing,
          reason: 'no page dots for a single city');
    });

    testWidgets('swiping shows the next city and loads its weather',
        (tester) async {
      await storeFavorites([City.berlin, tokyo, newYork]);
      final wttr = FakeWttr();
      await pumpPage(tester, const HomePage(),
          settings: await loadSettings(), weather: wttr.service);
      expect(find.text('Berlin'), findsOneWidget);
      expect(find.bySemanticsLabel('City 1 of 3'), findsOneWidget);

      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Tokyo'), findsOneWidget);
      expect(find.bySemanticsLabel('City 2 of 3'), findsOneWidget);
      expect(wttr.requests.map((uri) => uri.path), ['/Berlin', '/Tokyo']);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(CityRepository.currentIndexKey), 1);
    });

    testWidgets('opens the city shown last', (tester) async {
      await storeFavorites([City.berlin, tokyo, newYork], index: 2);

      await pumpPage(tester, const HomePage(), settings: await loadSettings());

      expect(find.text('New York'), findsOneWidget);
      expect(find.bySemanticsLabel('City 3 of 3'), findsOneWidget);
    });

    testWidgets('the widget shows the first city, not the one on screen',
        (tester) async {
      await storeFavorites([tokyo, City.berlin], index: 1);
      final widget = HomeWidgetRecorder.install();

      await pumpPage(tester, const HomePage(), settings: await loadSettings());
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Berlin'), findsOneWidget);
      expect(widget.valuesOf('city'), everyElement('Tokyo'));
    });

    testWidgets('keeps showing the same city after the list changed',
        (tester) async {
      await storeFavorites([City.berlin, tokyo], index: 1);
      await pumpPage(tester, const HomePage(), settings: await loadSettings());
      expect(find.text('Tokyo'), findsOneWidget);

      await tester.tap(find.text('Manage cities'));
      await tester.pumpAndSettle();
      await CityRepository().saveFavorites([newYork, tokyo, City.berlin]);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      expect(find.text('Tokyo'), findsOneWidget);
      expect(find.bySemanticsLabel('City 2 of 3'), findsOneWidget);
    });
  });

  group('cached weather', () {
    Future<void> storeFavorites(List<City> favorites) async {
      SharedPreferences.setMockInitialValues({
        CityRepository.favoritesKey:
            jsonEncode(favorites.map((city) => city.toJson()).toList()),
      });
    }

    testWidgets('other cities load from a new server once they are shown',
        (tester) async {
      await storeFavorites([City.berlin, tokyo]);
      final wttr = FakeWttr();
      final settings = await loadSettings();
      await pumpPage(tester, const HomePage(),
          settings: settings, weather: wttr.service);
      Future<void> swipe(double dx) async {
        await tester.fling(find.byType(PageView), Offset(dx, 0), 1000);
        await tester.pumpAndSettle();
      }

      // Tokyo is cached from the default server.
      await swipe(-300);
      await swipe(300);
      expect(wttr.requests.map((uri) => '${uri.host}${uri.path}'),
          ['wttr.in/Berlin', 'wttr.in/Tokyo']);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await settings.setWttrServer('https://example.org');
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      await swipe(-300);

      expect(wttr.requests.map((uri) => '${uri.host}${uri.path}').skip(2),
          ['example.org/Berlin', 'example.org/Tokyo']);
    });

    testWidgets('a recent report in another language is not reused',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final wttr = FakeWttr();
      await wttr.service
          .refresh(server: 'https://wttr.in', zone: 'Berlin', lang: 'de');

      await pumpPage(tester, const HomePage(),
          settings: await loadSettings(), weather: wttr.service);

      expect(find.text('☁️ Cloudy +20°C'), findsOneWidget);
      expect(wttr.requests.last.queryParameters['lang'], isNull);
    });
  });
}
