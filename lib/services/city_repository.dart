import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/models/country_zone.dart';

/// Loads the bundled city list and persists custom cities and the favorites.
class CityRepository {
  CityRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  /// The single city of versions before 1.11; kept equal to the first
  /// favorite so a downgrade still finds a city.
  static const selectedCityKey = 'selectedOption';
  static const customCitiesKey = 'customCities';
  static const favoritesKey = 'favoriteCities';
  static const currentIndexKey = 'currentCityIndex';
  static const widgetCitiesKey = 'widgetCities';

  final AssetBundle _bundle;

  Future<List<City>> loadAllCities() async =>
      [...await loadBundledCities(), ...await loadCustomCities()];

  /// The cities shipped with the app. Loaded once.
  Future<List<City>> loadBundledCities() =>
      _bundledCities ??= _loadBundledCities();

  Future<List<City>> _loadBundledCities() async {
    try {
      // Cached here rather than in the bundle, which would keep the string.
      final response = await _bundle.loadString(citiesAsset, cache: false);
      return [
        for (final city in json.decode(response) as List)
          City.fromJson(city as Map<String, dynamic>),
      ];
    } catch (_) {
      // Try again next time.
      _bundledCities = null;
      rethrow;
    }
  }

  static const citiesAsset = 'assets/data/cities.json';
  Future<List<City>>? _bundledCities;
  Future<Map<City, City>>? _bundledByIdentity;

  /// Replaces stored copies of bundled cities by their current bundled
  /// version, so fixes to the city list (e.g. a corrected UTC offset) reach
  /// favorites and widget cities saved by older versions. Custom cities and
  /// cities that are no longer bundled stay as stored.
  Future<City Function(City)> _resolver() async {
    final Map<City, City> bundled;
    try {
      bundled = await (_bundledByIdentity ??= loadBundledCities()
          .then((cities) => {for (final city in cities) city: city}));
    } catch (error) {
      _bundledByIdentity = null;
      debugPrint('Could not load $citiesAsset: $error');
      return (City city) => city;
    }
    return (City city) => city.isCustom ? city : bundled[city] ?? city;
  }

  /// The time zones of each country by ISO code, from the tz database.
  /// Loaded once, when the first custom city dialog opens.
  Future<Map<String, List<CountryZone>>> loadCountryZones() =>
      _countryZones ??= _bundle
          .loadString(countryZonesAsset)
          .then(CountryZone.parseAll)
          .catchError((Object error) {
            // The dialog still offers the zones of the bundled cities.
            debugPrint('Could not load $countryZonesAsset: $error');
            return <String, List<CountryZone>>{};
          });

  static const countryZonesAsset = 'assets/data/country_zones.json';
  Future<Map<String, List<CountryZone>>>? _countryZones;

  Future<List<City>> loadCustomCities() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString(customCitiesKey);
    if (custom == null) return [];
    try {
      return (jsonDecode(custom) as List)
          .map((city) => City.fromJson(city as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCustomCities(Iterable<City> cities) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      customCitiesKey,
      jsonEncode(cities.map((city) => city.toJson()).toList()),
    );
  }

  /// The cities shown on the home screen, never empty. Older versions stored
  /// a single city, which becomes the first favorite.
  Future<List<City>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(favoritesKey);
    if (stored != null) {
      try {
        final resolve = await _resolver();
        final favorites = <City>[];
        for (final json in jsonDecode(stored) as List) {
          final city = resolve(City.fromJson(json as Map<String, dynamic>));
          if (!favorites.contains(city)) favorites.add(city);
        }
        if (favorites.isNotEmpty) return favorites;
      } catch (_) {
        // Fall back to the migration below.
      }
    }
    return [await loadSelectedCity() ?? City.berlin];
  }

  Future<void> saveFavorites(List<City> favorites) async {
    assert(favorites.isNotEmpty, 'at least one city must stay');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      favoritesKey,
      jsonEncode(favorites.map((city) => city.toJson()).toList()),
    );
    await saveSelectedCity(favorites.first);
  }

  /// Index of the favorite shown last on the home screen.
  Future<int> loadCurrentIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(currentIndexKey) ?? 0;
  }

  Future<void> saveCurrentIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(currentIndexKey, index);
  }

  /// Cities of home screen widgets that were given their own city, by
  /// Android widget ID. Other widgets show the first favorite.
  Future<Map<int, City>> loadWidgetCities() async {
    final prefs = await SharedPreferences.getInstance();
    // Android configures a widget in a second instance of the app, whose
    // writes this instance's cached preferences would not see.
    await prefs.reload();
    final stored = prefs.getString(widgetCitiesKey);
    if (stored == null) return {};
    try {
      final resolve = await _resolver();
      return {
        for (final MapEntry(:key, :value)
            in (jsonDecode(stored) as Map<String, dynamic>).entries)
          int.parse(key): resolve(City.fromJson(value as Map<String, dynamic>)),
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> saveWidgetCity(int widgetId, City city) =>
      _updateWidgetCities((cities) => {...cities, widgetId: city});

  Future<void> removeWidgetCities(Iterable<int> widgetIds) =>
      _updateWidgetCities(
          (cities) => cities..removeWhere((id, _) => widgetIds.contains(id)));

  /// Gives widgets that show [city] its edited version [replacement], or
  /// without one returns them to the first favorite.
  Future<void> replaceWidgetCity(City city, City? replacement) =>
      _updateWidgetCities((cities) {
        final ids = [
          for (final MapEntry(:key, :value) in cities.entries)
            if (value == city) key,
        ];
        if (ids.isEmpty) return null;
        for (final id in ids) {
          if (replacement == null) {
            cities.remove(id);
          } else {
            cities[id] = replacement;
          }
        }
        return cities;
      });

  // Changes run one after another, so concurrent changes do not read the
  // same old map and overwrite each other.
  Future<void> _widgetCitiesChange = Future.value();

  /// Stores what [update] makes of the stored widget cities; `null` keeps
  /// them unchanged.
  Future<void> _updateWidgetCities(
      Map<int, City>? Function(Map<int, City> cities) update) {
    final change = _widgetCitiesChange.then((_) async {
      final updated = update(await loadWidgetCities());
      if (updated != null) await _saveWidgetCities(updated);
    });
    _widgetCitiesChange = change.catchError((_) {});
    return change;
  }

  Future<void> _saveWidgetCities(Map<int, City> cities) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(widgetCitiesKey, jsonEncode({
      for (final MapEntry(:key, :value) in cities.entries)
        '$key': value.toJson(),
    }));
  }

  /// Returns the stored selection, or `null` if there is none or it is broken.
  Future<City?> loadSelectedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(selectedCityKey);
    if (stored == null) return null;
    try {
      final city = City.fromJson(jsonDecode(stored) as Map<String, dynamic>);
      return (await _resolver())(city);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSelectedCity(City city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(selectedCityKey, jsonEncode(city.toJson()));
  }
}
