import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/pages/location/city_tile.dart';
import 'package:world_clock_v2/pages/location/custom_city_dialog.dart';
import 'package:world_clock_v2/pages/location/sort_menu.dart';
import 'package:world_clock_v2/services/city_repository.dart';
import 'package:world_clock_v2/theme/app_theme.dart';
import 'package:world_clock_v2/utils/city_sorting.dart';
import 'package:world_clock_v2/widgets/world_map/world_map.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  List<City> _cities = [];
  String _query = '';
  CitySort _sort = CitySort.city;
  bool _showMap = false;
  City _selected = City.berlin;

  CityRepository get _repository => context.read<CityRepository>();

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    final cities = await _repository.loadAllCities();
    final selected = await _repository.loadSelectedCity();
    if (!mounted) return;
    setState(() {
      _cities = cities;
      _selected = selected ?? City.berlin;
    });
  }

  void _select(City city) {
    setState(() => _selected = city);
    _repository.saveSelectedCity(city);
  }

  Future<void> _editCustomCity({City? editing}) async {
    final city = await showCustomCityDialog(
      context,
      cities: _cities,
      editing: editing,
    );
    if (city == null || !mounted) return;

    setState(() {
      final position = _cities.indexWhere((item) => identical(item, editing));
      if (position >= 0) {
        _cities[position] = city;
      } else {
        _cities.add(city);
      }
      _selected = city;
    });
    await _repository.saveCustomCities(_cities.where((item) => item.isCustom));
    await _repository.saveSelectedCity(city);
  }

  Future<void> _deleteCustomCity(City city) async {
    setState(() {
      _cities.removeWhere((item) => identical(item, city));
      if (_selected == city) _selected = City.berlin;
    });
    await _repository.saveCustomCities(_cities.where((item) => item.isCustom));
    await _repository.saveSelectedCity(_selected);
  }

  void _close() {
    HapticFeedback.lightImpact();
    Navigator.pop(context, _selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final visibleCities = sortCities(filterCities(_cities, _query), _sort);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        actions: [
          SortMenu(onSelected: (sort) => setState(() => _sort = sort)),
        ],
        centerTitle: true,
        title: Text(
          l10n.chooseCity,
          style: TextStyle(
            fontFamily: AppTheme.accentFontFamily,
            fontSize: 24,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        backgroundColor: colorScheme.primaryContainer,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, semanticLabel: l10n.ok),
          onPressed: _close,
        ),
      ),
      body: _showMap
          ? WorldMap(
              cities: _cities,
              selectedCity: _selected,
              onCityTap: (city) {
                _select(city);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text(l10n.citySelected(city.name))),
                  );
              },
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: TextField(
                    onChanged: (query) => setState(() => _query = query),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: l10n.searchHint(visibleCities.length),
                      prefixIcon:
                          Icon(Icons.search, semanticLabel: l10n.searchCity),
                    ),
                  ),
                ),
                Expanded(
                  child: RadioGroup<City>(
                    groupValue: _selected,
                    onChanged: (city) {
                      if (city == null) return;
                      HapticFeedback.lightImpact();
                      _select(city);
                    },
                    child: ListView.builder(
                      itemCount: visibleCities.length,
                      itemBuilder: (context, index) {
                        final city = visibleCities[index];
                        return CityTile(
                          city: city,
                          onEdit: () => _editCustomCity(editing: city),
                          onDelete: () => _deleteCustomCity(city),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'addCustomCity',
            tooltip: l10n.addCustomCity,
            backgroundColor: colorScheme.tertiary,
            foregroundColor: colorScheme.onTertiary,
            onPressed: () {
              HapticFeedback.lightImpact();
              _editCustomCity();
            },
            child: const Icon(Icons.add_location_alt_rounded),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'toggleMap',
            tooltip: _showMap ? l10n.showList : l10n.showMap,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            onPressed: () => setState(() => _showMap = !_showMap),
            child: Icon(_showMap ? Icons.list_rounded : Icons.map_rounded),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'confirmCity',
            onPressed: _close,
            backgroundColor: colorScheme.secondary,
            foregroundColor: colorScheme.onSecondary,
            child: Icon(Icons.check, semanticLabel: l10n.ok),
          ),
        ],
      ),
    );
  }
}
