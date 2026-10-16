import 'package:flutter/material.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/services/city_repository.dart';
import 'package:world_clock_v2/services/home_widget_service.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:world_clock_v2/services/weather_service.dart';
import 'package:world_clock_v2/utils/weather_status.dart';

/// Pushes the cities and their weather to the home screen widgets: widgets
/// with their own city show it, all others the first favorite, independent
/// of which city the home screen currently shows.
class HomeWidgetSync {
  HomeWidgetSync({required this.cities, required this.weather});

  final CityRepository cities;
  final WeatherService weather;

  // Syncs run one after another, so an older one never overwrites a newer.
  static Future<void> _queue = Future.value();

  @visibleForTesting
  static void resetQueue() => _queue = Future.value();

  /// Reads all context-dependent values right away; the work itself runs
  /// after any sync that is still in progress.
  Future<void> sync(BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    return _queue = _queue.then((_) => _sync(
          l10n: l10n,
          colorScheme: colorScheme,
          // wttr.in translates the descriptions; English is its default.
          lang: language == 'en' ? null : language,
          settings: settings,
        ));
  }

  Future<void> _sync({
    required AppLocalizations l10n,
    required ColorScheme colorScheme,
    required String? lang,
    required SettingsProvider settings,
  }) async {
    try {
      var widgetCities = await cities.loadWidgetCities();
      // Forget widgets that were removed from the home screen.
      final installed = await HomeWidgetService.installedWidgetIds();
      final removed = installed == null
          ? const <int>[]
          : widgetCities.keys.where((id) => !installed.contains(id)).toList();
      if (removed.isNotEmpty) {
        await cities.removeWidgetCities(removed);
        widgetCities = {
          for (final MapEntry(:key, :value) in widgetCities.entries)
            if (!removed.contains(key)) key: value,
        };
      }

      final defaultCity = (await cities.loadFavorites()).first;
      final entries = <WidgetCity>[
        await _entry(null, defaultCity, l10n, lang, settings),
        for (final MapEntry(:key, :value) in widgetCities.entries)
          await _entry(key, value, l10n, lang, settings),
      ];
      await HomeWidgetService.update(
        cities: entries,
        removedWidgetIds: removed,
        colorScheme: colorScheme,
        settings: settings,
      );
    } catch (e) {
      debugPrint('Error syncing home widget: $e');
    }
  }

  Future<WidgetCity> _entry(int? widgetId, City city, AppLocalizations l10n,
      String? lang, SettingsProvider settings) async {
    final result = await weather.current(
      server: settings.wttrServer,
      zone: city.weatherZone,
      lang: lang,
    );
    final report = result.report;
    final fahrenheit = settings.useFahrenheit;
    return (
      widgetId: widgetId,
      city: city,
      // Without a report the widget shows the same status as the app.
      weather: report?.summary(fahrenheit: fahrenheit) ??
          weatherStatusText(l10n, failure: result.failure, isLoading: false),
      weatherIcon: report?.current.symbol ?? '🛜',
      temperature:
          report == null ? '' : '${report.current.temperature(fahrenheit)}°',
    );
  }
}
