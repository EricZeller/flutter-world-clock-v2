import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/pages/settings/settings_page.dart';

import '../helpers/test_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Finder switchFor(String title) => find.descendant(
        of: find.widgetWithText(ListTile, title),
        matching: find.byType(Switch),
      );

  testWidgets('toggles update the settings immediately', (tester) async {
    final settings = await loadSettings();
    await pumpPage(tester, const SettingsPage(), settings: settings);

    await tester.tap(switchFor('Use 24hr format'));
    await tester.tap(switchFor('Use °F'));
    await tester.pumpAndSettle();

    expect(settings.use24hr, isFalse);
    expect(settings.useFahrenheit, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('use24hr'), isFalse);
  });

  testWidgets('tapping the text of a setting toggles it', (tester) async {
    final settings = await loadSettings();
    await pumpPage(tester, const SettingsPage(), settings: settings);

    await tester.tap(find.text('Use °F'));
    await tester.pumpAndSettle();

    expect(settings.useFahrenheit, isTrue);
  });

  testWidgets('theme mode can be changed without restart', (tester) async {
    final settings = await loadSettings();
    await pumpPage(tester, const SettingsPage(), settings: settings);

    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();

    expect(settings.themeMode, ThemeMode.dark);
  });

  testWidgets('shows the color picker only for custom colors',
      (tester) async {
    final settings = await loadSettings();
    await pumpPage(tester, const SettingsPage(), settings: settings);
    expect(find.text('Select color'), findsNothing);

    await tester.tap(switchFor('Custom Material color'));
    await tester.pumpAndSettle();

    expect(settings.useCustomColor, isTrue);
    expect(find.text('Select color'), findsOneWidget);
  });

  testWidgets('rejects an invalid wttr.in server', (tester) async {
    final settings = await loadSettings();
    await pumpPage(tester, const SettingsPage(), settings: settings);

    await tester.enterText(find.byType(TextField), 'not a url');
    await tester.pump();

    expect(find.text('Invalid URL'), findsOneWidget);
    expect(settings.wttrServer, 'https://wttr.in');
  });

  testWidgets('saves a valid wttr.in server', (tester) async {
    final settings = await loadSettings();
    await pumpPage(tester, const SettingsPage(), settings: settings);

    await tester.enterText(find.byType(TextField), 'https://example.org');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(settings.wttrServer, 'https://example.org');
    expect(find.text('URL saved'), findsOneWidget);
  });

  testWidgets('warns about an unsaved server before leaving', (tester) async {
    final settings = await loadSettings();
    await pumpPage(tester, const SettingsPage(), settings: settings);

    await tester.enterText(find.byType(TextField), 'https://example.org');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(find.text('Unsaved changes'), findsOneWidget);
    expect(find.byType(SettingsPage), findsOneWidget);
  });
}
