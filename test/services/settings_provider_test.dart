import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:world_clock_v2/theme/app_theme.dart';

void main() {
  group('SettingsProvider', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('has sensible defaults without stored values', () async {
      final settings = SettingsProvider();
      await settings.load();

      expect(settings.themeMode, ThemeMode.system);
      expect(settings.use24hr, isTrue);
      expect(settings.showSeconds, isTrue);
      expect(settings.showSecondsLocal, isFalse);
      expect(settings.showMoreInfo, isTrue);
      expect(settings.useFahrenheit, isFalse);
      expect(settings.useCustomColor, isFalse);
      expect(settings.customColor.toARGB32(), Colors.indigo.toARGB32());
      expect(settings.colorIndex, 4);
      expect(settings.wttrServer, 'https://wttr.in');
      expect(settings.widgetOpacity, 0.8);
      expect(settings.widgetLayout, 'detailed');
    });

    test('loads values stored by previous app versions', () async {
      SharedPreferences.setMockInitialValues({
        'themeMode': 'Dark',
        'use24hr': false,
        'showSeconds': false,
        'showSecondsLocal': true,
        'spMoreInfo': false,
        'useFahrenheit': true,
        'useCustomColor': true,
        'customColor': Colors.red.toARGB32(),
        'colorIndex': 0,
        'wttrServer': 'https://example.org',
        'widgetOpacity': 0.5,
        'widgetLayout': 'compact',
      });

      final settings = SettingsProvider();
      await settings.load();

      expect(settings.themeMode, ThemeMode.dark);
      expect(settings.use24hr, isFalse);
      expect(settings.showSeconds, isFalse);
      expect(settings.showSecondsLocal, isTrue);
      expect(settings.showMoreInfo, isFalse);
      expect(settings.useFahrenheit, isTrue);
      expect(settings.useCustomColor, isTrue);
      expect(settings.customColor.toARGB32(), Colors.red.toARGB32());
      expect(settings.colorIndex, 0);
      expect(settings.wttrServer, 'https://example.org');
      expect(settings.widgetOpacity, 0.5);
      expect(settings.widgetLayout, 'compact');
    });

    test('falls back to defaults for invalid stored values', () async {
      SharedPreferences.setMockInitialValues({
        'themeMode': 'Purple',
        'colorIndex': 99,
      });

      final settings = SettingsProvider();
      await settings.load();

      expect(settings.themeMode, ThemeMode.system);
      expect(settings.colorIndex, SettingsProvider.defaultColorIndex);
    });

    test('setters notify listeners and persist values', () async {
      final settings = SettingsProvider();
      await settings.load();
      var notifications = 0;
      settings.addListener(() => notifications++);

      await settings.setThemeMode(ThemeMode.light);
      await settings.setUse24hr(false);
      await settings.setShowSeconds(false);
      await settings.setShowSecondsLocal(true);
      await settings.setShowMoreInfo(false);
      await settings.setUseFahrenheit(true);
      await settings.setUseCustomColor(true);
      await settings.setColorIndex(9);
      await settings.setWttrServer('https://example.org');
      await settings.setWidgetOpacity(0.3);
      await settings.setWidgetLayout('compact');

      expect(notifications, 11);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('themeMode'), 'Light');
      expect(prefs.getBool('use24hr'), isFalse);
      expect(prefs.getBool('showSeconds'), isFalse);
      expect(prefs.getBool('showSecondsLocal'), isTrue);
      expect(prefs.getBool('spMoreInfo'), isFalse);
      expect(prefs.getBool('useFahrenheit'), isTrue);
      expect(prefs.getBool('useCustomColor'), isTrue);
      expect(prefs.getInt('colorIndex'), 9);
      expect(prefs.getInt('customColor'), materialColors[9].toARGB32());
      expect(prefs.getString('wttrServer'), 'https://example.org');
      expect(prefs.getDouble('widgetOpacity'), 0.3);
      expect(prefs.getString('widgetLayout'), 'compact');
    });

    test('stored values survive a reload', () async {
      final settings = SettingsProvider();
      await settings.load();
      await settings.setThemeMode(ThemeMode.dark);
      await settings.setColorIndex(2);

      final reloaded = SettingsProvider();
      await reloaded.load();

      expect(reloaded.themeMode, ThemeMode.dark);
      expect(reloaded.colorIndex, 2);
      expect(reloaded.customColor.toARGB32(), materialColors[2].toARGB32());
    });
  });
}
