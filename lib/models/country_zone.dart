import 'dart:convert';

/// A time zone of a country from the tz database's zone.tab, bundled as
/// `assets/data/country_zones.json` by `tool/generate_time_zones.dart`.
class CountryZone {
  const CountryZone({
    required this.timeZone,
    required this.latitude,
    required this.longitude,
    this.comment = '',
    this.sameTime = const {},
  });

  /// The IANA id, such as `America/Vancouver`.
  final String timeZone;

  /// Coordinates of the zone's principal location, such as Vancouver.
  final double latitude;
  final double longitude;

  /// Where in the country the zone applies, such as
  /// `MST - BC (most areas)`; empty for a country with a single zone.
  final String comment;

  /// The zones of the country that have shown the same time as this one for
  /// decades and are offered as this one, by IANA id with their comment,
  /// such as `Europe/Busingen` for `Europe/Berlin`. A custom city saved with
  /// one of them still shows the right time.
  final Map<String, String> sameTime;

  /// The ISO code that keys a country's zones: `de` for the flag `de.webp`.
  static String countryCode(String flag) => flag.split('.').first.toLowerCase();

  /// Parses the generated asset: ISO code to `[zone, latitude, longitude]`
  /// lists, with the comment appended if there is one, followed by the
  /// [sameTime] zones if there are any.
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
              sameTime: zone.length > 4
                  ? (zone[4] as Map).cast<String, String>()
                  : const {},
            ),
        ],
    };
  }
}
