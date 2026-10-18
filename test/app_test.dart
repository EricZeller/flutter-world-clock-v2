import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/app.dart';
import 'package:world_clock_v2/pages/home/home_page.dart';
import 'package:world_clock_v2/services/city_repository.dart';
import 'package:world_clock_v2/services/weather_service.dart';

import 'helpers/fake_wttr.dart';
import 'helpers/test_app.dart';
import 'helpers/time_zones.dart';

void main() {
  setUpAll(initializeAppTimeZones);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('app language', () {
    Future<Locale> appLocaleFor(WidgetTester tester, Locale device) async {
      tester.platformDispatcher.localesTestValue = [device];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: await loadSettings()),
            Provider<CityRepository>.value(value: FakeCityRepository()),
            Provider<WeatherService>.value(value: FakeWttr().service),
          ],
          child: const WorldClockApp(),
        ),
      );
      await tester.pumpAndSettle();
      return Localizations.localeOf(tester.element(find.byType(HomePage)));
    }

    testWidgets('is English for an unsupported device language',
        (tester) async {
      expect(await appLocaleFor(tester, const Locale('it', 'IT')),
          const Locale('en'));
      expect(find.text('Manage cities'), findsOneWidget);
    });

    testWidgets('is English for a device language of another script',
        (tester) async {
      expect(await appLocaleFor(tester, const Locale('zh', 'CN')),
          const Locale('en'));
    });

    testWidgets('follows a supported device language', (tester) async {
      expect(await appLocaleFor(tester, const Locale('de', 'AT')),
          const Locale('de'));
    });

    testWidgets('uses Portuguese for any Portuguese region', (tester) async {
      expect(await appLocaleFor(tester, const Locale('pt', 'PT')),
          const Locale('pt'));
    });

    testWidgets('uses Portuguese for Brazil', (tester) async {
      expect(await appLocaleFor(tester, const Locale('pt', 'BR')),
          const Locale('pt'));
    });
  });
}
