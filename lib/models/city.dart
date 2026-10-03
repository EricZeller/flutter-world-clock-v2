class City {
  final String name;
  final String country;
  final String timeZone;
  final String flag;
  final String utc;
  final String weatherZone;
  final double? latitude;
  final double? longitude;
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
    this.isCustom = false,
  });

  /// City shown when nothing has been selected yet.
  static const berlin = City(
    name: 'Berlin',
    country: 'Germany',
    timeZone: 'Europe/Berlin',
    flag: 'de.png',
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
      'isCustom': isCustom,
    };
  }

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'],
      country: json['country'],
      timeZone: json['timeZone'],
      flag: json['flag'],
      utc: json['utc'],
      weatherZone: json['weatherZone'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isCustom: json['isCustom'] == true,
    );
  }

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
