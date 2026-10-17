import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/pages/location/anchored_scroll_controller.dart';
import 'package:world_clock_v2/pages/location/city_tile.dart';
import 'package:world_clock_v2/pages/location/custom_city_dialog.dart';
import 'package:world_clock_v2/pages/location/sort_menu.dart';
import 'package:world_clock_v2/services/city_repository.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:world_clock_v2/theme/app_theme.dart';
import 'package:world_clock_v2/utils/city_sorting.dart';
import 'package:world_clock_v2/utils/time_utils.dart';
import 'package:world_clock_v2/widgets/world_map/world_map.dart';

/// Manages the favorite cities shown on the home screen.
class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  List<City> _cities = [];
  List<City> _favorites = [City.berlin];
  String _query = '';
  CitySort _sort = CitySort.city;
  bool _showMap = false;
  final _scrollController = AnchoredScrollController();

  // Read once, so saving after an await never needs this page's context.
  late final CityRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = context.read<CityRepository>();
    _loadCities();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    final cities = await _repository.loadAllCities();
    final favorites = await _repository.loadFavorites();
    if (!mounted) return;
    setState(() {
      _cities = cities;
      _favorites = favorites;
    });
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// Adds or removes [city]; returns whether it is a favorite afterwards.
  ///
  /// The list entry [tapped] keeps its place on screen although the
  /// favorites above it grow or shrink.
  bool _toggleFavorite(City city, {BuildContext? tapped}) {
    final isFavorite = _favorites.contains(city);
    if (isFavorite && _favorites.length == 1) {
      _showMessage(AppLocalizations.of(context)!.keepOneCity);
      return true;
    }
    HapticFeedback.lightImpact();
    // While searching, the favorites are hidden and nothing moves.
    if (tapped != null && _query.trim().isEmpty) {
      _scrollController.keepInPlace(tapped);
    }
    setState(() {
      _favorites = isFavorite
          ? _favorites.where((item) => item != city).toList()
          : [..._favorites, city];
    });
    _repository.saveFavorites(_favorites);
    return !isFavorite;
  }

  void _onMapTap(City city) {
    final l10n = AppLocalizations.of(context)!;
    final wasFavorite = _favorites.contains(city);
    final isFavorite = _toggleFavorite(city);
    if (wasFavorite == isFavorite) return;
    final time = formatTimeInZone(
      city.timeZone,
      use24hr: context.read<SettingsProvider>().use24hr,
      showSeconds: false,
    );
    _showMessage(isFavorite
        ? l10n.cityAddedAt(city.name, time)
        : l10n.cityRemovedAt(city.name, time));
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final favorites = [..._favorites];
      favorites.insert(newIndex, favorites.removeAt(oldIndex));
      _favorites = favorites;
    });
    _repository.saveFavorites(_favorites);
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
      // A new city is shown right away; an edited one keeps its place and
      // stays a favorite only if it was one.
      final favoriteIndex = editing == null ? -1 : _favorites.indexOf(editing);
      if (favoriteIndex >= 0) {
        _favorites = [
          for (final (index, item) in _favorites.indexed)
            if (index == favoriteIndex)
              city
            else if (item != city)
              item,
        ];
      } else if (editing == null) {
        _favorites = [..._favorites.where((item) => item != city), city];
      }
    });
    // The favorites first: the home page reloads them as soon as this closes.
    await _repository.saveFavorites(_favorites);
    await _repository.saveCustomCities(_cities.where((item) => item.isCustom));
    if (editing != null) await _repository.replaceWidgetCity(editing, city);
  }

  Future<void> _deleteCustomCity(City city) async {
    setState(() {
      _cities.removeWhere((item) => identical(item, city));
      final favorites = _favorites.where((item) => item != city).toList();
      _favorites = favorites.isEmpty ? [City.berlin] : favorites;
    });
    await _repository.saveFavorites(_favorites);
    await _repository.saveCustomCities(_cities.where((item) => item.isCustom));
    // The home page syncs the widgets as soon as this page closes.
    await _repository.replaceWidgetCity(city, null);
  }

  void _close() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    // Above the scaffold, so a tap on the iOS status bar still scrolls the
    // list to the top.
    return PrimaryScrollController(
      controller: _scrollController,
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final visibleCities = sortCities(filterCities(_cities, _query), _sort);
    final showFavorites = _query.trim().isEmpty;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        actions: [
          SortMenu(onSelected: (sort) => setState(() => _sort = sort)),
        ],
        centerTitle: true,
        title: Text(
          l10n.manageCities,
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
              selectedCities: _favorites,
              onCityTap: _onMapTap,
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
                  child: CustomScrollView(
                    primary: true,
                    slivers: [
                      if (showFavorites) ...[
                        SliverToBoxAdapter(child: _header(l10n.favorites)),
                        SliverReorderableList(
                          itemCount: _favorites.length,
                          onReorderItem: _reorder,
                          itemBuilder: (context, index) => FavoriteTile(
                            key: ValueKey(_favorites[index]),
                            city: _favorites[index],
                            index: index,
                            onRemove: () => _toggleFavorite(_favorites[index]),
                          ),
                        ),
                        SliverToBoxAdapter(child: _header(l10n.allCities)),
                      ],
                      SliverList.builder(
                        itemCount: visibleCities.length,
                        itemBuilder: (context, index) {
                          final city = visibleCities[index];
                          return Builder(
                            builder: (tile) => CityTile(
                              city: city,
                              isFavorite: _favorites.contains(city),
                              onToggleFavorite: () =>
                                  _toggleFavorite(city, tapped: tile),
                              onEdit: () => _editCustomCity(editing: city),
                              onDelete: () => _deleteCustomCity(city),
                            ),
                          );
                        },
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 240)),
                    ],
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
