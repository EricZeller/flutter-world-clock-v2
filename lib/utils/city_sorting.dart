import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/utils/place_names.dart';
import 'package:world_clock_v2/utils/search.dart';
import 'package:world_clock_v2/utils/time_utils.dart';

enum CitySort { city, country, utc, continent }

/// Sorts cities with custom cities always listed first. Names are compared
/// ignoring case and diacritics, cities and countries as [names] shows them.
List<City> sortCities(
  Iterable<City> cities,
  CitySort sort, [
  PlaceNames names = PlaceNames.english,
]) {
  int compare(City a, City b) => switch (sort) {
        CitySort.city => compareNames(names.name(a), names.name(b)),
        CitySort.country => switch (
              compareNames(names.country(a), names.country(b))) {
            0 => compareNames(names.name(a), names.name(b)),
            final result => result,
          },
        CitySort.utc => compareUtc(a.utc, b.utc),
        CitySort.continent => a.timeZone.compareTo(b.timeZone),
      };

  return cities.toList()
    ..sort((a, b) {
      if (a.isCustom != b.isCustom) return a.isCustom ? -1 : 1;
      return compare(a, b);
    });
}

/// Orders UTC offsets like `-05:00` before `+00:00` before `+05:30`.
int compareUtc(String a, String b) =>
    (parseUtcOffset(a) ?? 0).compareTo(parseUtcOffset(b) ?? 0);

/// Search over name, country, time zone and UTC offset that ignores case
/// and diacritics. Cities are found by their names and countries in English
/// and in the language of [names], see [PlaceNames.searchText].
List<City> filterCities(
  Iterable<City> cities,
  String query, [
  PlaceNames names = PlaceNames.english,
]) {
  if (query.trim().isEmpty) return cities.toList();
  return cities
      .where((city) => matchesSearch(names.searchText(city), query))
      .toList();
}
