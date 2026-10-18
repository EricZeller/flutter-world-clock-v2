import 'dart:convert';

/// A time zone of a country from the tz database's zone.tab, bundled as
/// `assets/data/country_zones.json` by `tool/generate_time_zones.dart`.
class CountryZone {
  const CountryZone({
    required this.timeZone,
    required this.latitude,
    required this.longitude,
    this.comment = '',
  });

  /// The IANA id, such as `America/Vancouver`.
  final String timeZone;

  /// Coordinates of the zone's principal location, such as Vancouver.
  final double latitude;
  final double longitude;

  /// Where in the country the zone applies, such as
  /// `MST - BC (most areas)`; empty for a country with a single zone.
  final String comment;

  /// The ISO code that keys a country's zones: `de` for the flag `de.webp`.
  static String countryCode(String flag) => flag.split('.').first.toLowerCase();

  /// Parses the generated asset: ISO code to `[zone, latitude, longitude]`
  /// lists, with the comment appended if there is one.
  static Map<String, List<CountryZone>> parseAll(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    return {
      for (final MapEntry(:key, :value) in data.entries)
        key: [
          for (final zone in value as List)
            CountryZone(
              timeZone: zone[0] as String,
              latitude: (zone[1] as num).toDouble(),
              longitude: (zone[2] as num).toDouble(),
              comment: (zone as List).length > 3 ? zone[3] as String : '',
            ),
        ],
    };
  }
}
