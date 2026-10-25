class City {
  final String name;
  final String country;
  final String timeZone;
  final String flag;
  final String utc;
  final String weatherZone;
  final double? latitude;
  final double? longitude;

  /// Inhabitants of a bundled city (GeoNames), which decides how far the
  /// map has to be zoomed in for its name; `null` for a custom city.
  final int? population;

  /// Whether a bundled city is the capital of its country.
  final bool isCapital;
  final bool isCustom;

  const City({
    required this.name,
    required this.country,
    required this.timeZone,
    required this.flag,
    required this.utc,
    required this.weatherZone,
    this.latitude,
    this.longitude,
    this.population,
    this.isCapital = false,
    this.isCustom = false,
  });

  /// City shown when nothing has been selected yet.
  static const berlin = City(
    name: 'Berlin',
    country: 'Germany',
    timeZone: 'Europe/Berlin',
    flag: 'de.webp',
    utc: '+02:00',
    weatherZone: 'Berlin',
  );

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'country': country,
      'timeZone': timeZone,
      'flag': flag,
      'utc': utc,
      'weatherZone': weatherZone,
      'latitude': latitude,
      'longitude': longitude,
      if (population != null) 'population': population,
      if (isCapital) 'capital': true,
      'isCustom': isCustom,
    };
  }

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'],
      country: json['country'],
      timeZone: json['timeZone'],
      flag: migrateFlag(json['flag']),
      utc: json['utc'],
      weatherZone: json['weatherZone'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      population: (json['population'] as num?)?.toInt(),
      isCapital: json['capital'] == true,
      isCustom: json['isCustom'] == true,
    );
  }

  /// Maps a stored flag file name to the bundled flag asset.
  ///
  /// Flags used to be bundled as `assets/flags/<code>.png` and are now
  /// lossless WebP files. Cities saved by older versions still reference the
  /// `.png` name, so it is rewritten to the `.webp` file when they are
  /// loaded. Stored bundled cities are replaced by their current bundled
  /// version anyway (see `CityRepository`), so this matters for custom
  /// cities and for cities that are no longer bundled.
  static String migrateFlag(String flag) => flag.endsWith('.png')
      ? '${flag.substring(0, flag.length - 4)}.webp'
      : flag;

  // A city restored from preferences is a new instance, so cities are compared
  // by what identifies them rather than by reference.
  @override
  bool operator ==(Object other) =>
      other is City &&
      other.name == name &&
      other.country == country &&
      other.timeZone == timeZone &&
      other.isCustom == isCustom;

  @override
  int get hashCode => Object.hash(name, country, timeZone, isCustom);
}
