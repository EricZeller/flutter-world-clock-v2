import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:world_clock_v2/main.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  testWidgets('App should initialize and show title', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => SettingsProvider(),
        child: const MyApp(),
      ),
    );

    expect(find.text('World Clock v2'), findsOneWidget);
  });

  testWidgets('App should show default city Berlin', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => SettingsProvider(),
        child: const MyApp(),
      ),
    );
    
    await tester.pumpAndSettle();
    expect(find.text('Berlin'), findsOneWidget);
  });

  testWidgets('Settings button should be visible', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => SettingsProvider(),
        child: const MyApp(),
      ),
    );

    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('Menu should contain all items', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => SettingsProvider(),
        child: const MyApp(),
      ),
    );

    // Open menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Check menu items
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Change city'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Source Code'), findsOneWidget);
    expect(find.text('Report a bug'), findsOneWidget);
  });
}
