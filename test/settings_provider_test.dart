import 'package:flutter_test/flutter_test.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:flutter/material.dart';

void main() {
  group('SettingsProvider Tests', () {
    late SettingsProvider settingsProvider;

    setUp(() {
      settingsProvider = SettingsProvider();
    });

    test('Initial custom color should be default color', () {
      expect(settingsProvider.customColor, Colors.blue);
    });

    test('Setting custom color should update the color', () {
      const newColor = Colors.red;
      settingsProvider.setCustomColor(newColor);
      expect(settingsProvider.customColor, newColor);
    });

    test('Theme mode should be updateable', () {
      const newThemeMode = 'dark';
      settingsProvider.setThemeMode(newThemeMode);
      expect(spThemeMode, newThemeMode);
    });

    test('24-hour format should be toggleable', () {
      final initial = sp24hr;
      settingsProvider.toggle24Hour();
      expect(sp24hr, !initial);
    });

    test('Show seconds should be toggleable', () {
      final initial = showSeconds;
      settingsProvider.toggleShowSeconds();
      expect(showSeconds, !initial);
    });
  });
}