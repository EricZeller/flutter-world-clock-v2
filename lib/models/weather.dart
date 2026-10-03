import 'package:world_clock_v2/utils/weather_symbols.dart';

/// Formats a temperature like wttr.in does, e.g. `+18°C` or `-3°F`.
String formatTemperature(int value, {required bool fahrenheit}) =>
    '${value > 0 ? '+' : ''}$value°${fahrenheit ? 'F' : 'C'}';

typedef HourlySlot = ({DateTime time, HourlyForecast forecast});

/// Current weather and a short forecast for one location, parsed from the
/// wttr.in JSON format (`?format=j1`).
class WeatherReport {
  const WeatherReport({
    required this.current,
    required this.days,
    required this.fetchedAt,
  });

  final CurrentWeather current;
  final List<DailyForecast> days;
  final DateTime fetchedAt;

  DailyForecast? get today => days.isEmpty ? null : days.first;

  /// The next [count] three-hourly slots after [cityNow] (the city's local
  /// wall-clock time), starting with the slot that is currently running.
  List<HourlySlot> upcomingHours(DateTime cityNow, {int count = 8}) {
    final earliest = cityNow.subtract(const Duration(minutes: 90));
    return [
      for (final day in days)
        for (final hour in day.hours)
          (
            time: DateTime(day.date.year, day.date.month, day.date.day,
                hour.hour),
            forecast: hour,
          ),
    ].where((slot) => slot.time.isAfter(earliest)).take(count).toList();
  }

  /// One-line summary like `☀️ Sunny +18°C`, also used by the home widget.
  String summary({required bool fahrenheit}) =>
      '${current.symbol} ${current.description} '
      '${formatTemperature(current.temperature(fahrenheit), fahrenheit: fahrenheit)}';

  /// [lang] selects the translated descriptions requested via `&lang=`.
  factory WeatherReport.fromWttr(
    Map<String, dynamic> json, {
    required DateTime fetchedAt,
    String? lang,
  }) {
    final current = (json['current_condition'] as List).first;
    return WeatherReport(
      current: CurrentWeather.fromWttr(current, lang),
      days: [
        for (final day in json['weather'] as List? ?? const [])
          DailyForecast.fromWttr(day, lang),
      ],
      fetchedAt: fetchedAt,
    );
  }

  factory WeatherReport.fromJson(Map<String, dynamic> json) => WeatherReport(
        current: CurrentWeather.fromJson(json['current']),
        days: [
          for (final day in json['days'] as List) DailyForecast.fromJson(day),
        ],
        fetchedAt: DateTime.parse(json['fetchedAt']),
      );

  Map<String, dynamic> toJson() => {
        'current': current.toJson(),
        'days': days.map((day) => day.toJson()).toList(),
        'fetchedAt': fetchedAt.toIso8601String(),
      };
}

class CurrentWeather {
  const CurrentWeather({
    required this.code,
    required this.description,
    required this.tempC,
    required this.tempF,
    required this.feelsLikeC,
    required this.feelsLikeF,
    required this.humidity,
    required this.windKmph,
    required this.windMph,
  });

  final int code;
  final String description;
  final int tempC;
  final int tempF;
  final int feelsLikeC;
  final int feelsLikeF;
  final int humidity;
  final int windKmph;
  final int windMph;

  String get symbol => weatherSymbol(code);
  int temperature(bool fahrenheit) => fahrenheit ? tempF : tempC;
  int feelsLike(bool fahrenheit) => fahrenheit ? feelsLikeF : feelsLikeC;

  factory CurrentWeather.fromWttr(Map<String, dynamic> json, String? lang) =>
      CurrentWeather(
        code: _int(json['weatherCode']),
        description: _description(json, lang),
        tempC: _int(json['temp_C']),
        tempF: _int(json['temp_F']),
        feelsLikeC: _int(json['FeelsLikeC']),
        feelsLikeF: _int(json['FeelsLikeF']),
        humidity: _int(json['humidity']),
        windKmph: _int(json['windspeedKmph']),
        windMph: _int(json['windspeedMiles']),
      );

  factory CurrentWeather.fromJson(Map<String, dynamic> json) => CurrentWeather(
        code: json['code'],
        description: json['description'],
        tempC: json['tempC'],
        tempF: json['tempF'],
        feelsLikeC: json['feelsLikeC'],
        feelsLikeF: json['feelsLikeF'],
        humidity: json['humidity'],
        windKmph: json['windKmph'],
        windMph: json['windMph'],
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'description': description,
        'tempC': tempC,
        'tempF': tempF,
        'feelsLikeC': feelsLikeC,
        'feelsLikeF': feelsLikeF,
        'humidity': humidity,
        'windKmph': windKmph,
        'windMph': windMph,
      };
}

class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.minC,
    required this.maxC,
    required this.minF,
    required this.maxF,
    required this.sunrise,
    required this.sunset,
    required this.hours,
  });

  /// Local date of the city.
  final DateTime date;
  final int minC;
  final int maxC;
  final int minF;
  final int maxF;

  /// Local times as sent by wttr.in, e.g. `07:11 AM` or `No sunrise`.
  final String sunrise;
  final String sunset;
  final List<HourlyForecast> hours;

  int min(bool fahrenheit) => fahrenheit ? minF : minC;
  int max(bool fahrenheit) => fahrenheit ? maxF : maxC;

  /// The midday forecast represents the day; falls back to the first slot.
  HourlyForecast? get representative {
    if (hours.isEmpty) return null;
    return hours.firstWhere((hour) => hour.hour == 12,
        orElse: () => hours.first);
  }

  int get chanceOfRain => hours.fold(
      0, (highest, hour) => hour.chanceOfRain > highest ? hour.chanceOfRain : highest);

  factory DailyForecast.fromWttr(Map<String, dynamic> json, String? lang) {
    final astronomy = (json['astronomy'] as List?)?.firstOrNull ?? const {};
    return DailyForecast(
      date: DateTime.parse(json['date']),
      minC: _int(json['mintempC']),
      maxC: _int(json['maxtempC']),
      minF: _int(json['mintempF']),
      maxF: _int(json['maxtempF']),
      sunrise: '${astronomy['sunrise'] ?? ''}',
      sunset: '${astronomy['sunset'] ?? ''}',
      hours: [
        for (final hour in json['hourly'] as List? ?? const [])
          HourlyForecast.fromWttr(hour, lang),
      ],
    );
  }

  factory DailyForecast.fromJson(Map<String, dynamic> json) => DailyForecast(
        date: DateTime.parse(json['date']),
        minC: json['minC'],
        maxC: json['maxC'],
        minF: json['minF'],
        maxF: json['maxF'],
        sunrise: json['sunrise'],
        sunset: json['sunset'],
        hours: [
          for (final hour in json['hours'] as List) HourlyForecast.fromJson(hour),
        ],
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'minC': minC,
        'maxC': maxC,
        'minF': minF,
        'maxF': maxF,
        'sunrise': sunrise,
        'sunset': sunset,
        'hours': hours.map((hour) => hour.toJson()).toList(),
      };
}

class HourlyForecast {
  const HourlyForecast({
    required this.hour,
    required this.code,
    required this.description,
    required this.tempC,
    required this.tempF,
    required this.chanceOfRain,
  });

  /// Hour of the day (0-23) in the city's local time.
  final int hour;
  final int code;
  final String description;
  final int tempC;
  final int tempF;
  final int chanceOfRain;

  String get symbol => weatherSymbol(code);
  int temperature(bool fahrenheit) => fahrenheit ? tempF : tempC;

  factory HourlyForecast.fromWttr(Map<String, dynamic> json, String? lang) =>
      HourlyForecast(
        // wttr.in encodes the time as `0`, `300`, ..., `2100`.
        hour: _int(json['time']) ~/ 100,
        code: _int(json['weatherCode']),
        description: _description(json, lang),
        tempC: _int(json['tempC']),
        tempF: _int(json['tempF']),
        chanceOfRain: _int(json['chanceofrain']),
      );

  factory HourlyForecast.fromJson(Map<String, dynamic> json) => HourlyForecast(
        hour: json['hour'],
        code: json['code'],
        description: json['description'],
        tempC: json['tempC'],
        tempF: json['tempF'],
        chanceOfRain: json['chanceOfRain'],
      );

  Map<String, dynamic> toJson() => {
        'hour': hour,
        'code': code,
        'description': description,
        'tempC': tempC,
        'tempF': tempF,
        'chanceOfRain': chanceOfRain,
      };
}

int _int(Object? value) => int.tryParse('${value ?? ''}'.trim()) ?? 0;

/// Prefers the translation (`lang_de`, ...) and falls back to English.
String _description(Map<String, dynamic> json, String? lang) {
  final translated = lang == null ? null : json['lang_$lang'] as List?;
  final values = translated ?? json['weatherDesc'] as List? ?? const [];
  final value = values.isEmpty ? '' : '${values.first['value'] ?? ''}';
  return value.trim();
}
