import 'package:flutter/material.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/services/city_repository.dart';
import 'package:world_clock_v2/services/home_widget_service.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:world_clock_v2/services/weather_service.dart';
import 'package:world_clock_v2/utils/weather_status.dart';

/// Pushes the first favorite and its weather to the home screen widget,
/// independent of which city the home screen currently shows.
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
      final city = (await cities.loadFavorites()).first;
      final result = await weather.current(
        server: settings.wttrServer,
        zone: city.weatherZone,
        lang: lang,
      );
      final report = result.report;
      final fahrenheit = settings.useFahrenheit;
      await HomeWidgetService.update(
        city: city,
        // Without a report the widget shows the same status as the app.
        weather: report?.summary(fahrenheit: fahrenheit) ??
            weatherStatusText(l10n, failure: result.failure, isLoading: false),
        weatherIcon: report?.current.symbol ?? '🛜',
        temperature: report == null
            ? ''
            : '${report.current.temperature(fahrenheit)}°',
        colorScheme: colorScheme,
        settings: settings,
      );
    } catch (e) {
      debugPrint('Error syncing home widget: $e');
    }
  }
}
