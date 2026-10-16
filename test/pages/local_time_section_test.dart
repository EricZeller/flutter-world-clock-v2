import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/pages/home/local_time_section.dart';

import '../helpers/test_app.dart';
import '../helpers/time_zones.dart';

void main() {
  setUpAll(initializeAppTimeZones);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpSection(WidgetTester tester, City city, DateTime now) async {
    await pumpPage(
      tester,
      Scaffold(body: LocalTimeSection(city: city, clock: () => now)),
      settings: await loadSettings(),
    );
  }

  testWidgets('announces a daylight saving time change', (tester) async {
    await pumpSection(tester, City.berlin, DateTime.utc(2026, 10, 23, 12));

    expect(find.text('Clocks change in 2 days: -01:00'), findsOneWidget);
  });

  testWidgets('says tomorrow and today', (tester) async {
    await pumpSection(tester, City.berlin, DateTime.utc(2026, 10, 24, 12));
    expect(find.text('Clocks change tomorrow: -01:00'), findsOneWidget);

    await pumpSection(tester, City.berlin, DateTime.utc(2026, 10, 24, 23));
    expect(find.text('Clocks change today: -01:00'), findsOneWidget,
        reason: 'already the 25th in Berlin');
  });

  testWidgets('shows nothing without a change', (tester) async {
    await pumpSection(tester, tokyo, DateTime.utc(2026, 10, 23, 12));
    expect(find.byIcon(Icons.more_time_rounded), findsNothing);

    await pumpSection(tester, City.berlin, DateTime.utc(2026, 10, 1));
    expect(find.byIcon(Icons.more_time_rounded), findsNothing);
  });

  testWidgets('is hidden without the extra info', (tester) async {
    SharedPreferences.setMockInitialValues({'spMoreInfo': false});
    await pumpSection(tester, City.berlin, DateTime.utc(2026, 10, 23, 12));

    expect(find.byIcon(Icons.more_time_rounded), findsNothing);
  });
}
