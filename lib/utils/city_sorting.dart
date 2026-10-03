import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/utils/time_utils.dart';

enum CitySort { city, country, utc, continent }

/// Sorts cities with custom cities always listed first.
List<City> sortCities(Iterable<City> cities, CitySort sort) {
  int compare(City a, City b) => switch (sort) {
        CitySort.city => a.name.compareTo(b.name),
        CitySort.country => a.country.compareTo(b.country),
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

/// Case-insensitive search over name, country, time zone and UTC offset.
List<City> filterCities(Iterable<City> cities, String query) {
  final search = query.trim().toLowerCase();
  if (search.isEmpty) return cities.toList();
  return cities.where((city) {
    return city.name.toLowerCase().contains(search) ||
        city.country.toLowerCase().contains(search) ||
        city.timeZone.toLowerCase().contains(search) ||
        city.utc.toLowerCase().contains(search);
  }).toList();
}
