import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/services/city_repository.dart';
import 'package:world_clock_v2/services/home_widget_service.dart';
import 'package:world_clock_v2/services/home_widget_sync.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:world_clock_v2/services/weather_service.dart';
import 'package:world_clock_v2/theme/app_theme.dart';
import 'package:world_clock_v2/utils/city_sorting.dart';
import 'package:world_clock_v2/utils/place_names.dart';

/// Shown when a home screen widget is added or reconfigured on Android:
/// picks the city this one widget shows.
class WidgetCityPickerPage extends StatefulWidget {
  const WidgetCityPickerPage({super.key, required this.widgetId});

  final int widgetId;

  /// How long fresh weather may take before the configuration ends anyway.
  static const downloadLimit = Duration(seconds: 5);

  @override
  State<WidgetCityPickerPage> createState() => _WidgetCityPickerPageState();
}

class _WidgetCityPickerPageState extends State<WidgetCityPickerPage> {
  List<City> _cities = [];
  List<City> _favorites = [];
  City? _current;
  String _query = '';
  bool _saving = false;

  late final CityRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = context.read<CityRepository>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Once; the language, which the cities are sorted by, is known here.
    _loading ??= _load(PlaceNames.of(context));
  }

  Future<void>? _loading;

  Future<void> _load(PlaceNames names) async {
    final cities = await _repository.loadAllCities();
    final favorites = await _repository.loadFavorites();
    final widgetCities = await _repository.loadWidgetCities();
    if (!mounted) return;
    setState(() {
      _cities = sortCities(cities, CitySort.city, names);
      _favorites = favorites;
      _current = widgetCities[widget.widgetId] ?? favorites.first;
    });
  }

  Future<void> _choose(City city) async {
    if (_saving) return;
    HapticFeedback.lightImpact();
    setState(() {
      _current = city;
      _saving = true;
    });
    await _repository.saveWidgetCity(widget.widgetId, city);
    if (!mounted) return;
    final sync = HomeWidgetSync(
      cities: _repository,
      weather: context.read<WeatherService>(),
    );
    final settings = context.read<SettingsProvider>();
    // First from the cache, so the widget shows the chosen city even if the
    // download below is cut short when the configuration ends.
    await sync.sync(context, settings, download: false);
    if (!mounted) return;
    await sync
        .sync(context, settings)
        .timeout(WidgetCityPickerPage.downloadLimit, onTimeout: () {});
    await HomeWidgetService.finishConfigure();
  }

  Widget _header(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _tile(City city) {
    final isCurrent = city == _current;
    return ListTile(
      leading: SizedBox(
        width: 40,
        child: city.flag.isEmpty
            ? const Icon(Icons.star_rounded)
            : Image.asset('assets/flags/${city.flag}'),
      ),
      title: Text(
        PlaceNames.of(context).name(city),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(PlaceNames.of(context).details(city)),
      trailing: isCurrent
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      selected: isCurrent,
      onTap: () => _choose(city),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final results = filterCities(_cities, _query, PlaceNames.of(context));
    final showFavorites = _query.trim().isEmpty;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          l10n.widgetCity,
          style: TextStyle(
            fontFamily: AppTheme.accentFontFamily,
            fontSize: 24,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        backgroundColor: colorScheme.primaryContainer,
        bottom: _saving
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: TextField(
              onChanged: (query) => setState(() => _query = query),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.searchHint(results.length),
                prefixIcon: Icon(Icons.search, semanticLabel: l10n.searchCity),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                if (showFavorites) ...[
                  _header(l10n.favorites),
                  for (final city in _favorites) _tile(city),
                  _header(l10n.allCities),
                ],
                for (final city in results) _tile(city),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
