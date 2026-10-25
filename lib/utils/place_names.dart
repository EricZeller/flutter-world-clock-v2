import 'package:flutter/widgets.dart';
import 'package:world_clock_v2/data/place_names.g.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/models/country_zone.dart';
import 'package:world_clock_v2/utils/search.dart';

/// Countries and cities in an app language. Cities are stored with their
/// English name and the English name of their country, which are translated
/// when they are shown ([name], [country]), and can be found by the names of
/// [cityExonyms] besides their own.
@immutable
class PlaceNames {
  const PlaceNames(this.languageCode);

  /// The names of the app's language.
  factory PlaceNames.of(BuildContext context) =>
      PlaceNames(Localizations.localeOf(context).languageCode);

  static const english = PlaceNames('en');

  final String languageCode;

  /// The country of [city] in the language: Deutschland for Germany in
  /// German. Cities name their country in English and are translated by the
  /// ISO code of their flag, as long as they name that flag's country: older
  /// versions could save a custom city with any flag and any country, which
  /// is shown as it was entered.
  String country(City city) {
    if (city.flag.isEmpty) return city.country;
    final code = CountryZone.countryCode(city.flag);
    if (countryNames['en']![code] != city.country) return city.country;
    return countryNames[languageCode]?[code] ?? city.country;
  }

  /// The name [city] is shown with: München for Munich in German. A custom
  /// city is shown as it was entered.
  String name(City city) =>
      city.isCustom ? city.name : cityNames[languageCode]?[city.name] ?? city.name;

  /// The country and offset shown below a city: `Deutschland, UTC+02:00`.
  String details(City city) {
    final country = this.country(city);
    return '${country.isEmpty ? '' : '$country, '}UTC${city.utc}';
  }

  /// Other names of the bundled [city] in the language, such as München for
  /// Munich. A custom city is only found by its own name.
  List<String> otherNames(City city) => city.isCustom
      ? const []
      : cityExonyms[languageCode]?[city.name] ?? const [];

  /// Everything [city] is found by: its names, its country in English and
  /// in the language, its time zone and offset. See [matchesSearch].
  String searchText(City city) => searchTextOf([
        city.name,
        ...otherNames(city),
        city.country,
        country(city),
        city.timeZone,
        city.utc,
      ]);

  @override
  bool operator ==(Object other) =>
      other is PlaceNames && other.languageCode == languageCode;

  @override
  int get hashCode => languageCode.hashCode;
}
