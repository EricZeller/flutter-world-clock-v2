import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/models/weather.dart';
import 'package:world_clock_v2/pages/home/city_clock.dart';
import 'package:world_clock_v2/pages/home/forecast_sheet.dart';
import 'package:world_clock_v2/pages/home/local_time_section.dart';
import 'package:world_clock_v2/pages/home/weather_section.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:world_clock_v2/services/weather_service.dart';

/// Clock, weather and local time of one city on the home screen.
class CityPage extends StatefulWidget {
  const CityPage({
    super.key,
    required this.city,
    required this.isActive,
    required this.refreshGeneration,
    required this.onWeatherUpdated,
    required this.onManageCities,
  });

  final City city;

  /// Only the page on screen refreshes its weather in the background.
  final bool isActive;

  /// Incremented by the home page to request a refresh, e.g. after the
  /// wttr.in server was changed in the settings.
  final int refreshGeneration;

  final VoidCallback onWeatherUpdated;
  final VoidCallback onManageCities;

  @override
  State<CityPage> createState() => _CityPageState();
}

class _CityPageState extends State<CityPage> {
  // Retry sooner while offline so the weather recovers quickly.
  static const _offlineRetryInterval = Duration(minutes: 2);

  late final Timer _timer;
  late final AppLifecycleListener _lifecycle;
  WeatherReport? _weather;
  WeatherFailure? _weatherFailure;
  bool _weatherLoading = true;
  DateTime? _lastWeatherAttempt;
  ({String request, Future<void> future})? _pendingWeather;
  String? _weatherLanguage;
  // Server, place and language of the report shown, to notice when any of
  // them changes, e.g. in the settings while this page was not on screen.
  String? _shownRequest;

  @override
  void initState() {
    super.initState();
    // The clocks tick on their own; this only checks whether the weather is
    // due for a refresh.
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (widget.isActive && _isDue) _refreshWeather();
    });
    _lifecycle = AppLifecycleListener(onResume: () {
      if (widget.isActive && (_weatherFailure != null || _isDue)) {
        _refreshWeather();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // wttr.in translates the descriptions; English is its default.
    final languageCode = Localizations.localeOf(context).languageCode;
    _weatherLanguage = languageCode == 'en' ? null : languageCode;
    // First call, or the app language changed.
    if (_shownRequest != _request) _loadWeather();
  }

  @override
  void didUpdateWidget(CityPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shownRequest != _request) {
      // Other place, or the server changed in the settings.
      _loadWeather();
    } else if (widget.isActive &&
        (oldWidget.refreshGeneration != widget.refreshGeneration ||
            (!oldWidget.isActive && _isDue))) {
      _refreshWeather();
    }
  }

  String get _server => context.read<SettingsProvider>().wttrServer;

  String get _request => WeatherService.cacheKeyFor(
        server: _server,
        zone: widget.city.weatherZone,
        lang: _weatherLanguage,
      );

  @override
  void dispose() {
    _timer.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  bool get _isDue {
    final last = _lastWeatherAttempt;
    if (last == null) return true;
    final interval = _weatherFailure == WeatherFailure.network
        ? _offlineRetryInterval
        : WeatherService.refreshInterval;
    return DateTime.now().difference(last) >= interval;
  }

  /// Shows the cached report at once and only downloads a new one when the
  /// cached one is outdated, so swiping between cities costs no data.
  Future<void> _loadWeather() async {
    final request = _request;
    _shownRequest = request;
    final cached = await context.read<WeatherService>().loadCached(
          server: _server,
          zone: widget.city.weatherZone,
          lang: _weatherLanguage,
        );
    // A newer load (other place, server or language) supersedes this one.
    if (!mounted || _shownRequest != request) return;
    setState(() {
      _weather = cached;
      _weatherFailure = null;
      _lastWeatherAttempt = cached?.fetchedAt;
      _weatherLoading = _isDue;
    });
    if (_isDue) await _refreshWeather();
  }

  /// Fetches the weather unless the same request is already running.
  Future<void> _refreshWeather() {
    final city = widget.city;
    final server = _server;
    final language = _weatherLanguage;
    final request = _request;
    final pending = _pendingWeather;
    if (pending != null && pending.request == request) return pending.future;
    final future = _fetchWeather(request, city, server, language);
    _pendingWeather = (request: request, future: future);
    return future.whenComplete(() {
      if (identical(_pendingWeather?.future, future)) _pendingWeather = null;
    });
  }

  Future<void> _fetchWeather(
      String request, City city, String server, String? language) async {
    _lastWeatherAttempt = DateTime.now();
    final result = await context.read<WeatherService>().refresh(
          server: server,
          zone: city.weatherZone,
          lang: language,
        );
    // A newer request (other city, server or language) supersedes this one,
    // also when its recent cached report made a download unnecessary.
    if (!mounted ||
        _shownRequest != request ||
        _pendingWeather?.request != request) {
      return;
    }
    setState(() {
      _weather = result.report ?? _weather;
      _weatherFailure = result.failure;
      _weatherLoading = false;
    });
    widget.onWeatherUpdated();
  }

  void _showForecast() {
    final weather = _weather;
    if (weather == null) return;
    showForecastSheet(
      context,
      city: widget.city,
      report: weather,
      isOffline: _weatherFailure != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _refreshWeather,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              const SizedBox(height: 40.0),
              CityClock(city: widget.city),
              const SizedBox(height: 12.0),
              WeatherSection(
                report: _weather,
                failure: _weatherFailure,
                isLoading: _weatherLoading,
                onTap: _showForecast,
              ),
              Divider(
                height: 64.0,
                thickness: 2,
                indent: 30,
                endIndent: 30,
                color: colorScheme.primary,
              ),
              LocalTimeSection(city: widget.city),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onManageCities();
                },
                label: Text(
                  l10n.manageCities,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                icon: Icon(
                  Icons.edit_location_alt_outlined,
                  color: colorScheme.primary,
                  semanticLabel: l10n.manageCities,
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
