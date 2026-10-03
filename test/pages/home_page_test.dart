import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:world_clock_v2/pages/home/forecast_sheet.dart';
import 'package:world_clock_v2/pages/home/home_page.dart';

import '../helpers/fake_wttr.dart';
import '../helpers/test_app.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
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

  testWidgets('shows cached weather while offline', (tester) async {
    final wttr = FakeWttr();
    await wttr.service.refresh(server: 'https://wttr.in', zone: 'Berlin');
    wttr.offline = true;

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
}
