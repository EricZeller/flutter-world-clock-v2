import AppIntents
import WidgetKit

/// A city as offered in the widget's "Edit" menu.
struct CityEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "City")
    static var defaultQuery = CityQuery()

    let id: String
    let city: City

    /// Keeps the ID a widget asked for, even if it found a renamed city.
    init(_ city: City, id: String? = nil) {
        self.id = id ?? city.id
        self.city = city
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(city.name)", subtitle: "\(city.country)")
    }
}

struct CityQuery: EntityStringQuery {
    func entities(for identifiers: [CityEntity.ID]) async throws -> [CityEntity] {
        identifiers.compactMap { id in City.with(id: id).map { CityEntity($0, id: id) } }
    }

    /// Search by city or country name.
    func entities(matching string: String) async throws -> [CityEntity] {
        City.all
            .filter {
                $0.name.localizedStandardContains(string)
                    || $0.country.localizedStandardContains(string)
            }
            .map { CityEntity($0) }
    }

    func suggestedEntities() async throws -> [CityEntity] {
        City.all.map { CityEntity($0) }
    }

    func defaultResult() async -> CityEntity? {
        CityEntity(City.named(City.berlin.name) ?? .berlin)
    }
}

/// Lets each placed widget show its own city.
struct SelectCityIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select City"
    static var description = IntentDescription("Choose the city this widget shows.")

    @Parameter(title: "City")
    var city: CityEntity?

    init() {}

    var selectedCity: City {
        city?.city ?? City.named(City.berlin.name) ?? .berlin
    }
}
