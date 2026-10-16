import WidgetKit

struct ClockEntry: TimelineEntry {
    let date: Date
    let city: City
    let weather: Weather?
}

struct Provider: AppIntentTimelineProvider {
    /// One timeline covers this many minutes; reloading it refreshes the weather.
    static let timelineMinutes = 60

    func placeholder(in context: Context) -> ClockEntry {
        ClockEntry(date: Date(), city: .berlin, weather: .sample)
    }

    func snapshot(for configuration: SelectCityIntent, in context: Context) async -> ClockEntry {
        let city = configuration.selectedCity
        if context.isPreview {
            // The widget gallery should not wait for the network.
            return ClockEntry(
                date: Date(), city: city,
                weather: WeatherLoader.cached(zone: city.weatherZone) ?? .sample
            )
        }
        return ClockEntry(
            date: Date(), city: city,
            weather: await WeatherLoader.load(zone: city.weatherZone)
        )
    }

    /// One entry per minute, so the date, the day/night look and (before
    /// macOS 15) the time stay current without reloading the timeline.
    func timeline(for configuration: SelectCityIntent, in context: Context) async -> Timeline<ClockEntry> {
        let city = configuration.selectedCity
        let weather = await WeatherLoader.load(zone: city.weatherZone)
        let now = Date()
        let calendar = Calendar(identifier: .gregorian)
        let minute = calendar.dateInterval(of: .minute, for: now)?.start ?? now
        var entries = [ClockEntry(date: now, city: city, weather: weather)]
        for offset in 1...Self.timelineMinutes {
            if let date = calendar.date(byAdding: .minute, value: offset, to: minute) {
                entries.append(ClockEntry(date: date, city: city, weather: weather))
            }
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
}
