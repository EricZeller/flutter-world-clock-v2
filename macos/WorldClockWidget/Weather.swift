import Foundation

/// Current weather of a place, parsed from the wttr.in JSON format
/// (`?format=j1`) like `WeatherReport.fromWttr` in the app.
struct Weather: Codable, Sendable {
    let code: Int
    let description: String
    let tempC: Int
    let tempF: Int
    /// Where wttr.in found the weather; tells whether it is night there.
    let latitude: Double?
    let longitude: Double?
    let fetchedAt: Date

    /// Shown in the widget gallery, which should not wait for the network.
    static let sample = Weather(
        code: 113, description: "", tempC: 18, tempF: 64,
        latitude: nil, longitude: nil, fetchedAt: .distantPast
    )

    /// Formats the temperature like the app and wttr.in, e.g. `+18°C`.
    func temperature(fahrenheit: Bool) -> String {
        let value = fahrenheit ? tempF : tempC
        return "\(value > 0 ? "+" : "")\(value)°\(fahrenheit ? "F" : "C")"
    }

    /// The weather symbol; after sunset no symbol shows the sun.
    func symbol(at date: Date) -> String {
        let night = latitude.flatMap { latitude in
            longitude.map { Sun.isNight(latitude: latitude, longitude: $0, at: date) }
        } ?? false
        return WeatherSymbols.symbol(code: code, night: night)
    }

    /// Whether the sun is down, or `nil` without a known location.
    func isNight(at date: Date) -> Bool? {
        guard let latitude, let longitude else { return nil }
        return Sun.isNight(latitude: latitude, longitude: longitude, at: date)
    }

    init(code: Int, description: String, tempC: Int, tempF: Int,
         latitude: Double?, longitude: Double?, fetchedAt: Date) {
        self.code = code
        self.description = description
        self.tempC = tempC
        self.tempF = tempF
        self.latitude = latitude
        self.longitude = longitude
        self.fetchedAt = fetchedAt
    }

    init?(wttr data: Data, lang: String?, fetchedAt: Date) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let current = (json["current_condition"] as? [[String: Any]])?.first
        else { return nil }
        let area = (json["nearest_area"] as? [[String: Any]])?.first
        self.init(
            code: Self.int(current["weatherCode"]),
            description: Self.description(current, lang: lang),
            tempC: Self.int(current["temp_C"]),
            tempF: Self.int(current["temp_F"]),
            latitude: Double("\(area?["latitude"] ?? "")"),
            longitude: Double("\(area?["longitude"] ?? "")"),
            fetchedAt: fetchedAt
        )
    }

    private static func int(_ value: Any?) -> Int {
        Int("\(value ?? "")".trimmingCharacters(in: .whitespaces)) ?? 0
    }

    /// Prefers the translation (`lang_de`, ...) and falls back to English.
    private static func description(_ json: [String: Any], lang: String?) -> String {
        let translated = lang.flatMap { json["lang_\($0)"] as? [[String: Any]] }
        let values = translated ?? json["weatherDesc"] as? [[String: Any]] ?? []
        return "\(values.first?["value"] ?? "")".trimmingCharacters(in: .whitespaces)
    }
}

/// Loads the weather from wttr.in and keeps the last report of each place,
/// so a widget still shows it for a while when offline.
enum WeatherLoader {
    static let server = "https://wttr.in"
    /// Younger reports are reused, e.g. by several widgets of one city.
    static let maxAge: TimeInterval = 15 * 60
    /// Older reports are not shown at all.
    static let staleAfter: TimeInterval = 6 * 60 * 60

    /// The language of the widget's texts when wttr.in should translate the
    /// description; English needs no parameter.
    static var language: String? {
        let language = Bundle.main.preferredLocalizations.first ?? "en"
        return language == "en" ? nil : language
    }

    static func url(zone: String, lang: String?) -> URL? {
        // Same escaping as Dart's Uri.encodeComponent.
        let allowed = CharacterSet(charactersIn:
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.!~*'()")
        guard let path = zone.addingPercentEncoding(withAllowedCharacters: allowed)
        else { return nil }
        var query = "format=j1"
        if let lang { query += "&lang=\(lang)" }
        return URL(string: "\(server)/\(path)?\(query)")
    }

    /// A fresh or cached report, or `nil` if there is none. Never throws.
    static func load(zone: String, now: Date = Date()) async -> Weather? {
        let lang = language
        let key = "weather|\(server)|\(zone)|\(lang ?? "en")"
        let cached = cached(key: key)
        if let cached, now.timeIntervalSince(cached.fetchedAt) < maxAge {
            return cached
        }
        if let fresh = await fetch(zone: zone, lang: lang, now: now) {
            store(fresh, key: key)
            return fresh
        }
        guard let cached, now.timeIntervalSince(cached.fetchedAt) < staleAfter
        else { return nil }
        return cached
    }

    /// The cached report for the gallery preview, if any.
    static func cached(zone: String) -> Weather? {
        cached(key: "weather|\(server)|\(zone)|\(language ?? "en")")
    }

    private static func fetch(zone: String, lang: String?, now: Date) async -> Weather? {
        guard let url = url(zone: zone, lang: lang) else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200
        else { return nil }
        return Weather(wttr: data, lang: lang, fetchedAt: now)
    }

    private static func cached(key: String) -> Weather? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Weather.self, from: data)
    }

    private static func store(_ weather: Weather, key: String) {
        guard let data = try? JSONEncoder().encode(weather) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

/// Maps WorldWeatherOnline condition codes (as returned by wttr.in) to the
/// emoji wttr.in uses, like `weatherSymbol` in the app.
enum WeatherSymbols {
    static func symbol(code: Int, night: Bool) -> String {
        let symbol = conditions[code].flatMap { symbols[$0] } ?? "✨"
        return night ? nightSymbols[symbol] ?? symbol : symbol
    }

    private static let nightSymbols = ["☀️": "🌙", "⛅️": "☁️", "🌦": "🌧"]

    private static let conditions: [Int: String] = [
        113: "Sunny", 116: "PartlyCloudy", 119: "Cloudy", 122: "VeryCloudy",
        143: "Fog", 176: "LightShowers", 179: "LightSleetShowers",
        182: "LightSleet", 185: "LightSleet", 200: "ThunderyShowers",
        227: "LightSnow", 230: "HeavySnow", 248: "Fog", 260: "Fog",
        263: "LightShowers", 266: "LightRain", 281: "LightSleet",
        284: "LightSleet", 293: "LightRain", 296: "LightRain",
        299: "HeavyShowers", 302: "HeavyRain", 305: "HeavyShowers",
        308: "HeavyRain", 311: "LightSleet", 314: "LightSleet",
        317: "LightSleet", 320: "LightSnow", 323: "LightSnowShowers",
        326: "LightSnowShowers", 329: "HeavySnow", 332: "HeavySnow",
        335: "HeavySnowShowers", 338: "HeavySnow", 350: "LightSleet",
        353: "LightShowers", 356: "HeavyShowers", 359: "HeavyRain",
        362: "LightSleetShowers", 365: "LightSleetShowers",
        368: "LightSnowShowers", 371: "HeavySnowShowers",
        374: "LightSleetShowers", 377: "LightSleet", 386: "ThunderyShowers",
        389: "ThunderyHeavyRain", 392: "ThunderySnowShowers",
        395: "HeavySnowShowers",
    ]

    private static let symbols = [
        "Cloudy": "☁️", "Fog": "🌫", "HeavyRain": "🌧", "HeavyShowers": "🌧",
        "HeavySnow": "❄️", "HeavySnowShowers": "❄️", "LightRain": "🌦",
        "LightShowers": "🌦", "LightSleet": "🌧", "LightSleetShowers": "🌧",
        "LightSnow": "🌨", "LightSnowShowers": "🌨", "PartlyCloudy": "⛅️",
        "Sunny": "☀️", "ThunderyHeavyRain": "🌩", "ThunderyShowers": "⛈",
        "ThunderySnowShowers": "⛈", "VeryCloudy": "☁️",
    ]
}

/// Position of the sun, like `lib/utils/sun.dart` in the app.
enum Sun {
    /// Whether the sun is below the horizon at the place at [date].
    static func isNight(latitude: Double, longitude: Double, at date: Date) -> Bool {
        let sun = subsolarPoint(date)
        func rad(_ degrees: Double) -> Double { degrees * .pi / 180 }
        let elevation = sin(rad(latitude)) * sin(rad(sun.latitude))
            + cos(rad(latitude)) * cos(rad(sun.latitude))
            * cos(rad(longitude - sun.longitude))
        return elevation < 0
    }

    /// The point where the sun is directly overhead, accurate to about a degree.
    private static func subsolarPoint(_ date: Date) -> (latitude: Double, longitude: Double) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let year = calendar.component(.year, from: date)
        let startOfYear = calendar.date(from: DateComponents(year: year))!
        let day = date.timeIntervalSince(startOfYear) / 86_400
        let declination = -23.44 * cos(2 * .pi / 365 * (day + 10))
        // Equation of time in minutes: how far solar noon drifts from 12:00.
        let b = 2 * .pi * (day - 81) / 364
        let equationOfTime = 9.87 * sin(2 * b) - 7.53 * cos(b) - 1.5 * sin(b)
        let hours = date.timeIntervalSince(calendar.startOfDay(for: date)) / 3600
        var longitude = -15 * (hours - 12 + equationOfTime / 60)
        longitude = (longitude + 540).truncatingRemainder(dividingBy: 360) - 180
        return (declination, longitude)
    }
}
