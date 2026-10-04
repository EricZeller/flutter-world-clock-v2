import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/pages/widget_settings.dart';
import 'package:world_clock_v2/utils/time_utils.dart';

import '../helpers/home_widget_recorder.dart';
import '../helpers/test_app.dart';
import '../helpers/time_zones.dart';

void main() {
  setUpAll(initializeAppTimeZones);

  /// Texts for a clock that may tick over while the test runs.
  Finder anyOf(Iterable<String> texts) => find.byWidgetPredicate(
      (widget) => widget is Text && texts.contains(widget.data));

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
    String date() =>
        DateFormat('EEE, d. MMM', 'de').format(wallClockIn('Europe/Berlin'));
    final before = date();

    await pumpPage(tester, const WidgetSettingsPage(),
        settings: await loadSettings(), locale: const Locale('de'));

    expect(find.text('Vorschau'), findsOneWidget);
    expect(anyOf({before, date()}), findsOneWidget);
  });

  testWidgets('the preview shows the selected city in its time zone',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'selectedOption': jsonEncode(tokyo.toJson()),
    });
    String time() =>
        formatTimeInZone('Asia/Tokyo', use24hr: true, showSeconds: false);
    final before = time();

    await pumpPage(tester, const WidgetSettingsPage(),
        settings: await loadSettings());

    expect(find.text('Tokyo'), findsOneWidget);
    expect(find.text('Berlin'), findsNothing);
    expect(anyOf({before, time()}), findsOneWidget);
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

  testWidgets('the home screen widget is updated once the slider is released',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final widget = HomeWidgetRecorder.install();
    final settings = await loadSettings();
    await pumpPage(tester, const WidgetSettingsPage(), settings: settings);

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(Slider)));
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
    }
    expect(settings.widgetOpacity, lessThan(0.8),
        reason: 'the preview follows the slider while dragging');
    expect(widget.valuesOf('widgetOpacity'), isEmpty);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 500));

    expect(widget.valuesOf('widgetOpacity'),
        [settings.widgetOpacity.toString()]);
  });
}
