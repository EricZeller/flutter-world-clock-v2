import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/services/settings_provider.dart';

/// Pushes data to the Android home screen widget. Failures are only logged,
/// since the app must keep working on platforms without the widget.
class HomeWidgetService {
  static const _providerName = 'WorldClockWidgetProvider';

  // Updates run one after another so their writes never interleave.
  static Future<void> _queue = Future.value();

  /// Drops pending updates; each widget test runs in its own fake time zone,
  /// so a queue left over from a previous test would never complete.
  @visibleForTesting
  static void resetQueue() => _queue = Future.value();

  static Future<void> update({
    required City city,
    required String weather,
    required String weatherIcon,
    required ColorScheme colorScheme,
    required SettingsProvider settings,
  }) {
    // Capture the values now; settings may change while queued.
    final opacity = settings.widgetOpacity;
    final layout = settings.widgetLayout;
    final use24hr = settings.use24hr;
    return _enqueue(() async {
      await HomeWidget.saveWidgetData<String>('city', city.name);
      await HomeWidget.saveWidgetData<String>('weather', weather);
      await HomeWidget.saveWidgetData<String>('weather_icon', weatherIcon);
      await HomeWidget.saveWidgetData<String>('timeZone', city.timeZone);
      await HomeWidget.saveWidgetData<String>(
          'bgColor', colorToHex(colorScheme.primaryContainer));
      await HomeWidget.saveWidgetData<String>(
          'primaryColor', colorToHex(colorScheme.onPrimaryContainer));
      await HomeWidget.saveWidgetData<String>(
          'secondaryColor', colorToHex(colorScheme.primary));
      await HomeWidget.saveWidgetData<String>(
          'widgetOpacity', opacity.toString());
      await HomeWidget.saveWidgetData<String>('widgetLayout', layout);
      await HomeWidget.saveWidgetData<bool>('use24hr', use24hr);

      // Tiny delay to ensure SharedPreferences are flushed to disk
      await Future.delayed(const Duration(milliseconds: 100));
      await _refresh();
    });
  }

  static Future<void> updateTimeFormat(bool use24hr) {
    return _enqueue(() async {
      await HomeWidget.saveWidgetData<bool>('use24hr', use24hr);
      await _refresh();
    });
  }

  static Future<void> updateAppearance({
    required double opacity,
    required String layout,
  }) {
    return _enqueue(() async {
      await HomeWidget.saveWidgetData<String>(
          'widgetOpacity', opacity.toString());
      await HomeWidget.saveWidgetData<String>('widgetLayout', layout);
      await _refresh();
    });
  }

  static Future<void> _enqueue(Future<void> Function() task) {
    return _queue = _queue.then((_) async {
      try {
        await task();
      } catch (e) {
        debugPrint('Error updating home widget: $e');
      }
    });
  }

  static Future<void> _refresh() => HomeWidget.updateWidget(
        name: _providerName,
        androidName: _providerName,
      );

  static String colorToHex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';
}
