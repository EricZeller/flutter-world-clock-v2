import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/services/settings_provider.dart';

/// Pushes data to the Android home screen widget. Failures are only logged,
/// since the app must keep working on platforms without the widget.
class HomeWidgetService {
  static const _providerName = 'WorldClockWidgetProvider';

  static Future<void> update({
    required City city,
    required String? weather,
    required ColorScheme colorScheme,
    required SettingsProvider settings,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('city', city.name);
      // Keep the last known weather on the widget while loading.
      if (weather != null) {
        await HomeWidget.saveWidgetData<String>('weather', weather);
        await HomeWidget.saveWidgetData<String>(
            'weather_icon', weatherIconOf(weather));
      }
      await HomeWidget.saveWidgetData<String>('timeZone', city.timeZone);
      await HomeWidget.saveWidgetData<String>(
          'bgColor', colorToHex(colorScheme.primaryContainer));
      await HomeWidget.saveWidgetData<String>(
          'primaryColor', colorToHex(colorScheme.onPrimaryContainer));
      await HomeWidget.saveWidgetData<String>(
          'secondaryColor', colorToHex(colorScheme.primary));
      await HomeWidget.saveWidgetData<String>(
          'widgetOpacity', settings.widgetOpacity.toString());
      await HomeWidget.saveWidgetData<String>(
          'widgetLayout', settings.widgetLayout);
      await HomeWidget.saveWidgetData<bool>('use24hr', settings.use24hr);

      // Tiny delay to ensure SharedPreferences are flushed to disk
      await Future.delayed(const Duration(milliseconds: 100));
      await _refresh();
    } catch (e) {
      debugPrint('Error updating home widget: $e');
    }
  }

  static Future<void> updateTimeFormat(bool use24hr) async {
    try {
      await HomeWidget.saveWidgetData<bool>('use24hr', use24hr);
      await _refresh();
    } catch (e) {
      debugPrint('Error updating home widget: $e');
    }
  }

  static Future<void> updateAppearance({
    required double opacity,
    required String layout,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>(
          'widgetOpacity', opacity.toString());
      await HomeWidget.saveWidgetData<String>('widgetLayout', layout);
      await _refresh();
    } catch (e) {
      debugPrint('Error updating home widget: $e');
    }
  }

  static Future<void> _refresh() => HomeWidget.updateWidget(
        name: _providerName,
        androidName: _providerName,
      );

  /// The weather summary starts with its emoji, e.g. `☀️ Sunny +18°C`.
  static String weatherIconOf(String weather) {
    final parts = weather.trim().split(' ');
    return parts.first.isEmpty ? '☀️' : parts.first;
  }

  static String colorToHex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';
}
