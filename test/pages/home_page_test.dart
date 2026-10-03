import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:world_clock_v2/pages/home/home_page.dart';

import '../helpers/test_app.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  testWidgets('shows Berlin and its weather when nothing is selected',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final weather = FakeWeatherService();

    await pumpPage(tester, const HomePage(),
        settings: await loadSettings(), weather: weather);

    expect(find.text('Berlin'), findsOneWidget);
    expect(find.text('Germany, UTC+02:00'), findsOneWidget);
    expect(find.text('☀️ Sunny +18°C'), findsOneWidget);
    expect(weather.requestedZones, contains('Berlin'));
  });

  testWidgets('shows the stored city', (tester) async {
    SharedPreferences.setMockInitialValues({
      'selectedOption': jsonEncode(tokyo.toJson()),
    });

    await pumpPage(tester, const HomePage(), settings: await loadSettings());

    expect(find.text('Tokyo'), findsOneWidget);
    expect(find.text('Japan, UTC+09:00'), findsOneWidget);
  });

  testWidgets('hides extra info when disabled', (tester) async {
    SharedPreferences.setMockInitialValues({'spMoreInfo': false});

    await pumpPage(tester, const HomePage(), settings: await loadSettings());

    expect(find.text('Germany, UTC+02:00'), findsNothing);
    expect(find.byIcon(Icons.schedule_rounded), findsNothing);
  });

  testWidgets('shows a loading text until weather arrives', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await pumpPage(tester, const HomePage(),
        settings: await loadSettings(),
        weather: FakeWeatherService(summary: null));

    expect(find.text('🛰️ Loading...'), findsOneWidget);
  });

  testWidgets('reloads the weather after returning from settings',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final weather = FakeWeatherService();
    await pumpPage(tester, const HomePage(),
        settings: await loadSettings(), weather: weather);
    final requestsBefore = weather.requestedZones.length;

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('settings route'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    expect(weather.requestedZones.length, requestsBefore + 1);
  });
}
