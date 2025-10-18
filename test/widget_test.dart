import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:world_clock_v2/main.dart';
import 'package:world_clock_v2/services/settings_provider.dart';

void main() {
  group('MyApp Widget Tests', () {
    testWidgets('MyApp should render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => SettingsProvider(),
          child: const MyApp(),
        ),
      );

      expect(find.text('World Clock v2'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Settings button should be present', (WidgetTester tester) async {
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

      // Open the menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Change city'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Source Code'), findsOneWidget);
      expect(find.text('Report a bug'), findsOneWidget);
    });
  });
}