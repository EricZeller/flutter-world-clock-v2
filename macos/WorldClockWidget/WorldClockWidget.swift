import SwiftUI
import WidgetKit

@main
struct WorldClockWidget: Widget {
    let kind = "WorldClockWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectCityIntent.self, provider: Provider()) { entry in
            WorldClockWidgetView(entry: entry)
        }
        .configurationDisplayName("World Clock")
        .description("Shows the time and weather of a city.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WorldClockWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ClockEntry

    var body: some View {
        Group {
            switch family {
            case .systemMedium: MediumClockView(entry: entry)
            default: SmallClockView(entry: entry)
            }
        }
        .foregroundStyle(.white)
        .environment(\.timeZone, entry.city.zone)
        .containerBackground(for: .widget) {
            SkyBackground(night: entry.isNight)
        }
    }
}

// MARK: - Sizes

struct SmallClockView: View {
    let entry: ClockEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 4) {
                VStack(alignment: .leading, spacing: 1) {
                    CityName(name: entry.city.name, size: 16)
                    Text(entry.date, format: entry.shortDateStyle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if let weather = entry.weather {
                    Text(weather.symbol(at: entry.date))
                        .font(.system(size: 24))
                }
            }
            Spacer(minLength: 0)
            CityTime(entry: entry, size: 40)
            HStack(spacing: 4) {
                if let weather = entry.weather {
                    Text(weather.temperature(fahrenheit: entry.fahrenheit))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                Spacer(minLength: 0)
                DifferenceLabel(entry: entry)
            }
        }
    }
}

struct MediumClockView: View {
    let entry: ClockEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                CityName(name: entry.city.name, size: 20)
                Text(entry.city.country)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
                Spacer(minLength: 0)
                CityTime(entry: entry, size: 48)
                Text(entry.date, format: entry.longDateStyle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 2) {
                WeatherColumn(entry: entry)
                Spacer(minLength: 0)
                Label {
                    Text(verbatim: "UTC\(entry.utcOffset)")
                } icon: {
                    Image(systemName: "globe")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                DifferenceLabel(entry: entry)
            }
            .frame(maxWidth: 130, alignment: .trailing)
        }
    }
}

// MARK: - Parts

private struct CityName: View {
    let name: String
    let size: CGFloat

    var body: some View {
        Text(verbatim: name)
            .font(.system(size: size, weight: .bold, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }
}

/// The city's local time. From macOS 15 on it ticks by itself; before, each
/// timeline entry (one per minute) shows its own time.
private struct CityTime: View {
    let entry: ClockEntry
    let size: CGFloat

    var body: some View {
        time
            .font(.system(size: size, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .widgetAccentable()
    }

    @ViewBuilder private var time: some View {
        if #available(macOS 15, *) {
            Text(.currentDate, format: entry.timeStyle)
        } else {
            Text(entry.date, format: entry.timeStyle)
        }
    }
}

private struct WeatherColumn: View {
    let entry: ClockEntry

    var body: some View {
        if let weather = entry.weather {
            Text(weather.symbol(at: entry.date))
                .font(.system(size: 30))
            Text(weather.temperature(fahrenheit: entry.fahrenheit))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
            if !weather.description.isEmpty {
                Text(verbatim: weather.description)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
            }
        } else {
            Image(systemName: "wifi.slash")
                .font(.system(size: 20, weight: .medium))
                .padding(.bottom, 2)
            Text("Weather unavailable")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.trailing)
        }
    }
}

/// Difference to the local time, like the chip in the app.
private struct DifferenceLabel: View {
    let entry: ClockEntry

    var body: some View {
        Label {
            Text(verbatim: entry.differenceToLocal)
        } icon: {
            Image(systemName: "clock")
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.white.opacity(0.75))
        .accessibilityLabel(Text("Difference to local time"))
        .accessibilityValue(Text(verbatim: entry.differenceToLocal))
    }
}

/// A day or night sky in the colors of the Android widget.
struct SkyBackground: View {
    let night: Bool

    var body: some View {
        LinearGradient(
            colors: night
                ? [Color(red: 0.13, green: 0.17, blue: 0.38), Color(red: 0.02, green: 0.17, blue: 0.30)]
                : [Color(red: 0.16, green: 0.49, blue: 0.80), Color(red: 0.04, green: 0.62, blue: 0.62)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Formatting

extension ClockEntry {
    /// Day or night at the city: from the sun when wttr.in reported the
    /// location, otherwise from the local hour.
    var isNight: Bool {
        if let night = weather?.isNight(at: date) { return night }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = city.zone
        let hour = calendar.component(.hour, from: date)
        return hour < 6 || hour >= 20
    }

    /// Follows the system's measurement system and temperature setting.
    var fahrenheit: Bool {
        UnitTemperature(forLocale: .current, usage: .weather) == .fahrenheit
    }

    var timeStyle: Date.FormatStyle {
        var style = Date.FormatStyle(date: .omitted, time: .shortened)
        style.timeZone = city.zone
        return style
    }

    var shortDateStyle: Date.FormatStyle {
        var style = Date.FormatStyle().weekday(.abbreviated).day().month(.abbreviated)
        style.timeZone = city.zone
        return style
    }

    var longDateStyle: Date.FormatStyle {
        var style = Date.FormatStyle().weekday(.wide).day().month(.wide)
        style.timeZone = city.zone
        return style
    }

    /// E.g. `+02:00`, like the city list in the app.
    var utcOffset: String {
        Self.format(seconds: city.zone.secondsFromGMT(for: date))
    }

    var differenceToLocal: String {
        Self.format(seconds: city.zone.secondsFromGMT(for: date)
            - TimeZone.current.secondsFromGMT(for: date))
    }

    private static func format(seconds: Int) -> String {
        let minutes = abs(seconds) / 60
        return String(format: "%@%02d:%02d", seconds < 0 ? "-" : "+", minutes / 60, minutes % 60)
    }
}
