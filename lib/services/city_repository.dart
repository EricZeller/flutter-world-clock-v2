import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/models/city.dart';

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

  Future<List<City>> loadAllCities() async {
    final response = await _bundle.loadString('assets/data/cities.json');
    final data = json.decode(response) as List;
    return [
      ...data.map((city) => City.fromJson(city as Map<String, dynamic>)),
      ...await loadCustomCities(),
    ];
  }

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
        final favorites = <City>[];
        for (final json in jsonDecode(stored) as List) {
          final city = City.fromJson(json as Map<String, dynamic>);
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
      return {
        for (final MapEntry(:key, :value)
            in (jsonDecode(stored) as Map<String, dynamic>).entries)
          int.parse(key): City.fromJson(value as Map<String, dynamic>),
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> saveWidgetCity(int widgetId, City city) async {
    await _saveWidgetCities({...await loadWidgetCities(), widgetId: city});
  }

  Future<void> removeWidgetCities(Iterable<int> widgetIds) async {
    final cities = await loadWidgetCities()
      ..removeWhere((id, _) => widgetIds.contains(id));
    await _saveWidgetCities(cities);
  }

  /// Gives widgets that show [city] its edited version [replacement], or
  /// without one returns them to the first favorite.
  Future<void> replaceWidgetCity(City city, City? replacement) async {
    final cities = await loadWidgetCities();
    final ids = [
      for (final MapEntry(:key, :value) in cities.entries)
        if (value == city) key,
    ];
    if (ids.isEmpty) return;
    for (final id in ids) {
      if (replacement == null) {
        cities.remove(id);
      } else {
        cities[id] = replacement;
      }
    }
    await _saveWidgetCities(cities);
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
      return City.fromJson(jsonDecode(stored) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSelectedCity(City city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(selectedCityKey, jsonEncode(city.toJson()));
  }
}
