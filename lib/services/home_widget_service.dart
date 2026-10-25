import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/services/settings_provider.dart';

typedef WidgetCity = ({
  int? widgetId,
  City city,

  /// The name shown, in the app's language.
  String name,
  String weather,
  String weatherIcon,
  String temperature,
});

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

  /// Writes the cities of all widgets and refreshes them once. Entries
  /// without a widget ID are the default for widgets without their own city.
  static Future<void> update({
    required List<WidgetCity> cities,
    Iterable<int> removedWidgetIds = const [],
    required ColorScheme colorScheme,
    required SettingsProvider settings,
  }) {
    // Capture the values now; settings may change while queued.
    final opacity = settings.widgetOpacity;
    final layout = settings.widgetLayout;
    final use24hr = settings.use24hr;
    final removed = removedWidgetIds.toList();
    return _enqueue(() async {
      for (final entry in cities) {
        final suffix = keySuffix(entry.widgetId);
        await HomeWidget.saveWidgetData<String>('city$suffix', entry.name);
        await HomeWidget.saveWidgetData<String>(
            'weather$suffix', entry.weather);
        await HomeWidget.saveWidgetData<String>(
            'weather_icon$suffix', entry.weatherIcon);
        await HomeWidget.saveWidgetData<String>(
            'weather_temp$suffix', entry.temperature);
        await HomeWidget.saveWidgetData<String>(
            'timeZone$suffix', entry.city.timeZone);
      }
      for (final widgetId in removed) {
        for (final key in cityKeys) {
          await HomeWidget.saveWidgetData<String>(
              '$key${keySuffix(widgetId)}', null);
        }
      }
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

  /// Keys that each widget can have for its own city.
  static const cityKeys = [
    'city', 'weather', 'weather_icon', 'weather_temp', 'timeZone', //
  ];

  /// The native widget reads `city_<id>` first and falls back to `city`.
  static String keySuffix(int? widgetId) =>
      widgetId == null ? '' : '_$widgetId';

  /// The widget ID if Android started the app to choose a widget's city.
  static Future<int?> configureRequest() async {
    try {
      final id = await HomeWidget.initiallyLaunchedFromHomeWidgetConfigure();
      return id == null ? null : int.tryParse(id);
    } catch (_) {
      return null; // Not on Android.
    }
  }

  /// Ends the configuration and returns to the home screen.
  static Future<void> finishConfigure() async {
    try {
      await HomeWidget.finishHomeWidgetConfigure();
    } catch (e) {
      debugPrint('Error finishing widget configuration: $e');
    }
  }

  /// IDs of the widgets on the home screen, or `null` if unknown.
  static Future<List<int>?> installedWidgetIds() async {
    try {
      return [
        for (final widget in await HomeWidget.getInstalledWidgets())
          ?widget.androidWidgetId,
      ];
    } catch (_) {
      return null;
    }
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
