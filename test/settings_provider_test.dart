import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:flutter/material.dart';

void main() {
  group('SettingsProvider Tests', () {
    late SettingsProvider settingsProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      settingsProvider = SettingsProvider();
    });

    tearDown(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    test('Default values should be set correctly', () {
      expect(settingsProvider.customColor, equals(Colors.indigo));
      expect(settingsProvider.useCustomColor, equals(false));
    });

    test('Settings should be loaded from SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('customColor', Colors.red.value);
      await prefs.setBool('useCustomColor', true);

      // Create a new instance to test loading
      settingsProvider = SettingsProvider();
      
      // Wait for the provider to load the settings
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(settingsProvider.customColor.value, equals(Colors.red.value));
      expect(settingsProvider.useCustomColor, equals(true));
    });
  });
}