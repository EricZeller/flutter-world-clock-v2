import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/models/city.dart';

/// Loads the bundled city list and persists custom cities and the selection.
class CityRepository {
  CityRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const selectedCityKey = 'selectedOption';
  static const customCitiesKey = 'customCities';

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
