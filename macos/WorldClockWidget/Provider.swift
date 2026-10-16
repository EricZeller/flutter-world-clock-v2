import WidgetKit

struct ClockEntry: TimelineEntry {
    let date: Date
    let city: City
    let weather: Weather?
}

struct Provider: AppIntentTimelineProvider {
    /// One timeline covers this many minutes; reloading it refreshes the weather.
    static let timelineMinutes = 60
    /// Without a fresh report (e.g. the Mac woke before the network was
    /// back), the weather is tried again this much sooner.
    static let retryMinutes = 15

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
            weather: await WeatherLoader.load(zone: city.weatherZone).weather
        )
    }

    /// One entry per minute, so the date, the day/night look and (before
    /// macOS 15) the time stay current without reloading the timeline.
    func timeline(for configuration: SelectCityIntent, in context: Context) async -> Timeline<ClockEntry> {
        let city = configuration.selectedCity
        let result = await WeatherLoader.load(zone: city.weatherZone)
        let minutes = result.isFresh ? Self.timelineMinutes : Self.retryMinutes
        let now = Date()
        let calendar = Calendar(identifier: .gregorian)
        let minute = calendar.dateInterval(of: .minute, for: now)?.start ?? now
        var dates = [now]
        for offset in 1...minutes {
            if let date = calendar.date(byAdding: .minute, value: offset, to: minute) {
                dates.append(date)
            }
        }
        // A cached report disappears once it gets too old, not only on reload.
        let entries = dates.map { date in
            ClockEntry(
                date: date, city: city,
                weather: result.weather.flatMap { $0.isStale(at: date) ? nil : $0 }
            )
        }
        // Reloads after the last entry, which also fetches the weather again.
        return Timeline(entries: entries, policy: .atEnd)
    }
}
