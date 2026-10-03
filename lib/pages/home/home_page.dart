import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/models/weather.dart';
import 'package:world_clock_v2/pages/home/city_clock.dart';
import 'package:world_clock_v2/pages/home/forecast_sheet.dart';
import 'package:world_clock_v2/pages/home/home_menu.dart';
import 'package:world_clock_v2/pages/home/local_time_section.dart';
import 'package:world_clock_v2/pages/home/weather_section.dart';
import 'package:world_clock_v2/services/city_repository.dart';
import 'package:world_clock_v2/services/home_widget_service.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:world_clock_v2/services/weather_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _refreshInterval = Duration(minutes: 15);
  // Retry sooner while offline so the weather recovers quickly.
  static const _offlineRetryInterval = Duration(minutes: 2);

  late final Timer _timer;
  late final AppLifecycleListener _lifecycle;
  City _city = City.berlin;
  WeatherReport? _weather;
  WeatherFailure? _weatherFailure;
  bool _weatherLoading = true;
  DateTime _lastWeatherAttempt = DateTime.now();
  ({String zone, Future<void> future})? _pendingWeather;
  String? _weatherLanguage;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
      final interval = _weatherFailure == WeatherFailure.network
          ? _offlineRetryInterval
          : _refreshInterval;
      if (DateTime.now().difference(_lastWeatherAttempt) >= interval) {
        _refreshWeather();
      }
    });
    _lifecycle = AppLifecycleListener(onResume: () {
      if (_weatherFailure != null ||
          DateTime.now().difference(_lastWeatherAttempt) >= _refreshInterval) {
        _refreshWeather();
      }
    });
    _loadCity();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // wttr.in translates the descriptions; English is its default.
    final languageCode = Localizations.localeOf(context).languageCode;
    final language = languageCode == 'en' ? null : languageCode;
    final languageChanged = _weatherLanguage != language;
    _weatherLanguage = language;
    if (languageChanged && !_weatherLoading) _refreshWeather();
    // Theme changes alter the widget colors.
    _updateHomeWidget();
  }

  @override
  void dispose() {
    _timer.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _loadCity() async {
    final city =
        await context.read<CityRepository>().loadSelectedCity() ?? City.berlin;
    if (!mounted) return;
    final changed =
        city != _city || city.weatherZone != _city.weatherZone;
    if (changed || _weather == null) {
      final cached =
          await context.read<WeatherService>().loadCached(city.weatherZone);
      if (!mounted) return;
      setState(() {
        _city = city;
        _weather = cached;
        _weatherFailure = null;
        _weatherLoading = true;
      });
    }
    _updateHomeWidget();
    await _refreshWeather();
  }

  /// Fetches the weather unless a request for the same place is running.
  Future<void> _refreshWeather() {
    final zone = _city.weatherZone;
    final pending = _pendingWeather;
    if (pending != null && pending.zone == zone) return pending.future;
    final future = _fetchWeather();
    _pendingWeather = (zone: zone, future: future);
    return future.whenComplete(() {
      if (identical(_pendingWeather?.future, future)) _pendingWeather = null;
    });
  }

  Future<void> _fetchWeather() async {
    _lastWeatherAttempt = DateTime.now();
    final city = _city;
    final result = await context.read<WeatherService>().refresh(
          server: context.read<SettingsProvider>().wttrServer,
          zone: city.weatherZone,
          lang: _weatherLanguage,
        );
    if (!mounted || city != _city) return;
    setState(() {
      _weather = result.report ?? _weather;
      _weatherFailure = result.failure;
      _weatherLoading = false;
    });
    _updateHomeWidget();
  }

  void _updateHomeWidget() {
    final settings = context.read<SettingsProvider>();
    HomeWidgetService.update(
      city: _city,
      weather: _weather?.summary(fahrenheit: settings.useFahrenheit),
      colorScheme: Theme.of(context).colorScheme,
      settings: settings,
    );
  }

  Future<void> _openSettings() async {
    await Navigator.pushNamed(context, '/settings');
    _refreshWeather();
  }

  Future<void> _changeCity() async {
    await Navigator.pushNamed(context, '/location');
    _loadCity();
  }

  void _showForecast() {
    final weather = _weather;
    if (weather == null) return;
    showForecastSheet(
      context,
      city: _city,
      report: weather,
      isOffline: _weatherFailure != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.primaryContainer,
      appBar: AppBar(
        actions: [
          HomeMenu(onOpenSettings: _openSettings, onChangeCity: _changeCity),
        ],
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        title: Text(l10n.appTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshWeather,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const SizedBox(height: 40.0),
                  CityClock(city: _city),
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
                  LocalTimeSection(city: _city),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _changeCity();
                    },
                    label: Text(
                      l10n.changeCity,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    icon: Icon(
                      Icons.edit_location_alt_outlined,
                      color: colorScheme.primary,
                      semanticLabel: l10n.changeCity,
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        onPressed: () {
          HapticFeedback.lightImpact();
          _openSettings();
        },
        child: Icon(Icons.settings, semanticLabel: l10n.settings),
      ),
    );
  }
}
