import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/pages/home/city_clock.dart';
import 'package:world_clock_v2/pages/home/home_menu.dart';
import 'package:world_clock_v2/pages/home/local_time_section.dart';
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
  static const _weatherRefreshInterval = Duration(minutes: 15);

  late final Timer _timer;
  City _city = City.berlin;
  String? _weather;
  DateTime _lastWeatherRefresh = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
      if (DateTime.now().difference(_lastWeatherRefresh) >=
          _weatherRefreshInterval) {
        _refreshWeather();
      }
    });
    _loadCity();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Theme changes alter the widget colors.
    _updateHomeWidget();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadCity() async {
    final city = await context.read<CityRepository>().loadSelectedCity();
    if (!mounted) return;
    setState(() => _city = city ?? City.berlin);
    _updateHomeWidget();
    await _refreshWeather();
  }

  Future<void> _refreshWeather() async {
    _lastWeatherRefresh = DateTime.now();
    final settings = context.read<SettingsProvider>();
    final weather = await context.read<WeatherService>().fetchSummary(
          server: settings.wttrServer,
          zone: _city.weatherZone,
          fahrenheit: settings.useFahrenheit,
        );
    if (!mounted || weather == null) return;
    setState(() => _weather = weather);
    _updateHomeWidget();
  }

  void _updateHomeWidget() {
    HomeWidgetService.update(
      city: _city,
      weather: _weather,
      colorScheme: Theme.of(context).colorScheme,
      settings: context.read<SettingsProvider>(),
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
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const SizedBox(height: 40.0),
                CityClock(city: _city),
                const SizedBox(height: 20.0),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _weather ?? l10n.weatherLoading,
                    style: TextStyle(
                      fontSize: 20.0,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                Divider(
                  height: 80.0,
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
