import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/pages/widget_settings.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('the preview label is readable in light mode', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpPage(tester, const WidgetSettingsPage(),
        settings: await loadSettings());

    final label = tester.widget<Text>(find.text('Preview'));
    final colorScheme =
        Theme.of(tester.element(find.text('Preview'))).colorScheme;
    expect(label.style!.color, colorScheme.onSurfaceVariant);
  });

  testWidgets('the preview shows the date in the app language',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpPage(tester, const WidgetSettingsPage(),
        settings: await loadSettings(), locale: const Locale('de'));

    expect(find.text('Vorschau'), findsOneWidget);
    expect(find.text(DateFormat('EEE, d. MMM', 'de').format(DateTime.now())),
        findsOneWidget);
  });

  testWidgets('the preview follows the 12-hour setting', (tester) async {
    SharedPreferences.setMockInitialValues({'use24hr': false});
    await pumpPage(tester, const WidgetSettingsPage(),
        settings: await loadSettings());

    expect(find.textContaining(RegExp(r'^\d{2}:\d{2} [AP]M$')),
        findsOneWidget);
  });

  testWidgets('the compact preview fits a 12-hour time', (tester) async {
    SharedPreferences.setMockInitialValues(
        {'use24hr': false, 'widgetLayout': 'compact'});
    await pumpPage(tester, const WidgetSettingsPage(),
        settings: await loadSettings());

    expect(tester.takeException(), isNull);
    expect(find.textContaining(RegExp(r'^\d{2}:\d{2} [AP]M$')),
        findsOneWidget);
  });
}
