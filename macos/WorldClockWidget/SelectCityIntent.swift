import AppIntents
import WidgetKit

/// A city as offered in the widget's "Edit" menu.
struct CityEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "City")
    static var defaultQuery = CityQuery()

    let id: String
    let city: City

    init(_ city: City) {
        id = city.name
        self.city = city
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(city.name)", subtitle: "\(city.country)")
    }
}

struct CityQuery: EntityStringQuery {
    func entities(for identifiers: [CityEntity.ID]) async throws -> [CityEntity] {
        identifiers.compactMap(City.named).map(CityEntity.init)
    }

    /// Search by city or country name.
    func entities(matching string: String) async throws -> [CityEntity] {
        City.all
            .filter {
                $0.name.localizedStandardContains(string)
                    || $0.country.localizedStandardContains(string)
            }
            .map(CityEntity.init)
    }

    func suggestedEntities() async throws -> [CityEntity] {
        City.all.map(CityEntity.init)
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
