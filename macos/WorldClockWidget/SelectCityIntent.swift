import AppIntents
import WidgetKit

/// The cities of the widget's "Edit" menu, grouped by their first letter.
///
/// The choice is a plain `String` ("Berlin, Germany"), not an `AppEntity`:
/// macOS only turns a stored entity back into a value if the entity type is
/// registered system-wide, which fails for an ad-hoc signed app without a
/// team ID, so every widget fell back to Berlin.
struct CityOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> ItemCollection<String> {
        let groups = Dictionary(grouping: City.all) { String($0.name.prefix(1)).uppercased() }
        let sections = groups.keys.sorted().map { letter in
            ItemSection<String>(
                "\(letter)",
                items: (groups[letter] ?? []).map { city in
                    IntentItem(city.label, title: "\(city.name)", subtitle: "\(city.localizedCountry)")
                }
            )
        }
        return ItemCollection(usesIndexedCollation: true, sections: sections)
    }

    func defaultResult() async -> String? {
        City.berlin.label
    }
}

/// Lets each placed widget show its own city.
struct SelectCityIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Select City"
    static let description = IntentDescription("Choose the city this widget shows.")

    @Parameter(title: "City", optionsProvider: CityOptionsProvider())
    var city: String?

    init() {}

    var selectedCity: City {
        city.flatMap(City.labeled) ?? City.named(City.berlin.name) ?? .berlin
    }
}
