import Foundation

/// A city of the app's list. The extension bundles `assets/data/cities.json`
/// itself (copied at build time), so it needs no data from the app.
struct City: Decodable, Hashable, Sendable {
    let name: String
    let country: String
    let timeZone: String
    let weatherZone: String

    /// Shown until a city is chosen, like in the app.
    static let berlin = City(
        name: "Berlin",
        country: "Germany",
        timeZone: "Europe/Berlin",
        weatherZone: "Berlin"
    )

    /// All cities, sorted by name.
    static let all: [City] = {
        guard let url = Bundle.main.url(forResource: "cities", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let cities = try? JSONDecoder().decode([City].self, from: data),
              !cities.isEmpty
        else { return [berlin] }
        return cities.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }()

    /// Names are unique in cities.json, so they identify a city.
    static func named(_ name: String) -> City? {
        all.first { $0.name == name }
    }

    /// An unknown zone falls back to UTC instead of breaking the widget.
    var zone: TimeZone {
        TimeZone(identifier: timeZone) ?? TimeZone(secondsFromGMT: 0)!
    }
}
