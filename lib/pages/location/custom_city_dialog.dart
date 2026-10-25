import 'package:flutter/material.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/models/country_zone.dart';
import 'package:world_clock_v2/utils/place_names.dart';
import 'package:world_clock_v2/utils/search.dart';
import 'package:world_clock_v2/utils/time_utils.dart';

/// Shows a dialog to create a custom city, or edit [editing] if given.
/// The available countries and flags are taken from the bundled cities among
/// [cities]. A country offers the time zones of its cities and those of
/// [countryZones] for its flag, see `CityRepository.loadCountryZones`.
Future<City?> showCustomCityDialog(
  BuildContext context, {
  required List<City> cities,
  Map<String, List<CountryZone>> countryZones = const {},
  City? editing,
}) {
  return showDialog<City>(
    context: context,
    builder: (context) => CustomCityDialog(
      cities: cities,
      countryZones: countryZones,
      editing: editing,
    ),
  );
}

/// A country of the bundled cities, identified by its flag: the flags are
/// named by ISO code, so Hong Kong stays apart from the rest of China
/// although the cities of both name China as their country.
class _Country {
  _Country(this.flag, this.name);

  final String flag;

  /// The English name the country's cities are saved with.
  final String name;
  final cities = <City>[];

  /// The name in the app's language, see [PlaceNames.country].
  late final String localName;

  /// The [localName], followed by its capital or biggest city if another
  /// flag has the same name: China (Beijing) and China (Hong Kong).
  late final String label;

  /// The time zones of [cities] and of the tz database for this country,
  /// by IANA id and sorted by label.
  late final Map<String, _Zone> zones;

  /// Everything the country can be found by: its label, its English name
  /// and its cities, see [PlaceNames.searchText].
  late final String searchText;

  /// The zone of [zones] that [timeZone] is or is offered as, such as
  /// `Europe/Berlin` for `Europe/Busingen`, see [CountryZone.sameTime].
  String? zoneFor(String? timeZone) => zones.containsKey(timeZone)
      ? timeZone
      : zones.values
          .where((zone) =>
              zone.countryZone?.sameTime.containsKey(timeZone) ?? false)
          .firstOrNull
          ?.timeZone;
}

/// The capital among [cities], else the most populous, else the first.
City _mainCity(List<City> cities) =>
    cities.where((city) => city.isCapital).firstOrNull ??
    cities.reduce(
      (a, b) => (b.population ?? 0) > (a.population ?? 0) ? b : a,
    );

/// A time zone of a country: one of the tz database's zones of the country,
/// one of its bundled cities, or usually both.
class _Zone {
  _Zone(this.timeZone);

  final String timeZone;

  /// The zone in the tz database's list of the country's zones.
  CountryZone? countryZone;

  /// The bundled cities of the country in this zone.
  final cities = <City>[];

  /// Where in the country the zone applies, such as
  /// `MST - BC (most areas)`.
  String get comment => countryZone?.comment ?? '';

  /// Everything the zone can be found by: its label, its cities, where it
  /// applies and the zones it is offered for.
  late final String searchText;
}

class CustomCityDialog extends StatefulWidget {
  const CustomCityDialog({
    super.key,
    required this.cities,
    this.countryZones = const {},
    this.editing,
  });

  final List<City> cities;

  /// The time zones of each country by ISO code, see [CountryZone].
  final Map<String, List<CountryZone>> countryZones;

  final City? editing;

  @override
  State<CustomCityDialog> createState() => _CustomCityDialogState();
}

class _CustomCityDialogState extends State<CustomCityDialog> {
  late final TextEditingController _nameController;
  final _countryController = TextEditingController();
  final _timeZoneController = TextEditingController();

  /// The names of the app's language, which the countries are labeled in.
  PlaceNames? _names;
  List<_Country> _countries = const [];
  Map<String, _Country> _countriesByFlag = const {};
  _Country? _country;
  String? _timeZone;

  /// The country of an edited city that is none of [_countries]; shown as an
  /// error until another country is picked or typed.
  String? _unknownCountry;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.editing?.name);
  }

  /// Labels the countries in the app's language, which is only known here.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final names = PlaceNames.of(context);
    if (names == _names) return;
    final isFirst = _names == null;
    _names = names;
    _countries = _countriesOf(widget.cities, widget.countryZones, names);
    _countriesByFlag = {
      for (final country in _countries) country.flag: country,
    };
    if (isFirst) {
      _showEditing();
    } else if (_country != null) {
      // The picked country, labeled in the new language.
      _country = _countriesByFlag[_country!.flag];
      _countryController.text = _country!.label;
    }
  }

  /// Fills in the city being edited and starts to watch the fields.
  void _showEditing() {
    final editing = widget.editing;
    if (editing != null) {
      _country = _matchCountry(editing);
      final country = editing.country.trim();
      if (_country != null) {
        _countryController.text = _country!.label;
      } else if (country.isNotEmpty) {
        _countryController.text = _unknownCountry = country;
      }
      // Shown even if it is no zone of the country, so it can be fixed. A
      // zone that is offered as another one, such as Europe/Busingen as
      // Europe/Berlin, is shown as that one.
      final zone = _country?.zoneFor(editing.timeZone) ?? editing.timeZone;
      _timeZone = zone;
      _timeZoneController.text = timeZoneLabel(zone);
    }

    // A typed search that was not confirmed by picking an entry must not
    // keep the previous selection.
    _countryController.addListener(() {
      if (_country != null && _countryController.text != _country!.label) {
        setState(() => _country = null);
      }
      if (_unknownCountry != null &&
          _countryController.text != _unknownCountry) {
        setState(() => _unknownCountry = null);
      }
    });
    _timeZoneController.addListener(() {
      if (_timeZone != null &&
          _timeZoneController.text != timeZoneLabel(_timeZone!)) {
        setState(() => _timeZone = null);
      }
    });
  }

  /// The countries of the bundled [cities], labeled in the language of
  /// [names] and sorted by label, with the zones of their cities and of
  /// [countryZones]. Custom cities are left out: they may spell their
  /// country differently.
  static List<_Country> _countriesOf(
    List<City> cities,
    Map<String, List<CountryZone>> countryZones,
    PlaceNames names,
  ) {
    final byFlag = <String, _Country>{};
    for (final city in cities) {
      if (city.isCustom || city.flag.isEmpty) continue;
      final country = byFlag.putIfAbsent(
        city.flag,
        () => _Country(city.flag, city.country)
          ..localName = names.country(city),
      );
      country.cities.add(city);
    }
    final flagsPerName = <String, int>{};
    for (final country in byFlag.values) {
      flagsPerName.update(
        country.localName,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    // A city's own name and those of its language, such as München.
    List<String> namesOf(City city) => [city.name, ...names.otherNames(city)];
    for (final country in byFlag.values) {
      final zones = <String, _Zone>{};
      // A country without zones in the tz database's list (Kosovo) still
      // has those of its cities.
      _Zone zoneOf(String timeZone) =>
          zones.putIfAbsent(timeZone, () => _Zone(timeZone));
      final code = CountryZone.countryCode(country.flag);
      for (final zone in countryZones[code] ?? const <CountryZone>[]) {
        zoneOf(zone.timeZone).countryZone ??= zone;
      }
      for (final city in country.cities) {
        zoneOf(city.timeZone).cities.add(city);
      }
      for (final zone in zones.values) {
        zone.searchText = searchTextOf([
          timeZoneLabel(zone.timeZone),
          for (final city in zone.cities) ...namesOf(city),
          zone.comment,
          for (final MapEntry(:key, :value)
              in zone.countryZone?.sameTime.entries ?? const [])
            ...[timeZoneLabel(key), value],
        ]);
      }
      country
        ..label = flagsPerName[country.localName]! > 1
            ? '${country.localName} (${_mainCity(country.cities).name})'
            : country.localName
        ..zones = {
          for (final zone in zones.values.toList()
            ..sort((a, b) => compareNames(
                timeZoneLabel(a.timeZone), timeZoneLabel(b.timeZone))))
            zone.timeZone: zone,
        }
        ..searchText = searchTextOf([
          country.label,
          country.name,
          for (final city in country.cities) ...namesOf(city),
        ]);
    }
    return byFlag.values.toList()
      ..sort((a, b) => compareNames(a.label, b.label));
  }

  /// The country [city] was saved with. Cities of older versions could
  /// combine any flag, country name and time zone, so the flag and the name
  /// are both tried, preferring a country that has the city's time zone and
  /// then the flag. The name may be in English or in the app's language. A
  /// city without country and without a known flag gets the only country of
  /// its zone.
  _Country? _matchCountry(City city) {
    bool hasZone(_Country country) => country.zoneFor(city.timeZone) != null;
    final name = foldForSearch(city.country.trim());
    if (name.isEmpty && !_countriesByFlag.containsKey(city.flag)) {
      final withZone = _countries.where(hasZone);
      return withZone.length == 1 ? withZone.single : null;
    }
    final candidates = _countries.where((country) =>
        country.flag == city.flag ||
        foldForSearch(country.name) == name ||
        foldForSearch(country.localName) == name);
    return candidates.where(hasZone).firstOrNull ??
        _countriesByFlag[city.flag] ??
        candidates.firstOrNull;
  }

  // Underlined like the text field above instead of the outlined default.
  static const _fieldStyle = InputDecorationThemeData(
    border: UnderlineInputBorder(),
    contentPadding: EdgeInsets.symmetric(vertical: 12),
    helperMaxLines: 2,
  );

  /// `America/New_York` reads better and is easier to find as
  /// `America/New York`.
  static String timeZoneLabel(String zone) => zone.replaceAll('_', ' ');

  static List<DropdownMenuEntry<String>> _filter(
    List<DropdownMenuEntry<String>> entries,
    String query,
    String Function(DropdownMenuEntry<String> entry) searchText,
  ) =>
      // Underscores as in the IANA id `America/New_York` match the label,
      // see foldForSearch.
      entries
          .where((entry) => matchesSearch(searchText(entry), query))
          .toList();

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _timeZoneController.dispose();
    super.dispose();
  }

  /// Picks the country of [flag] and keeps the time zone only if it is one
  /// of the country's, or offered as one of them. Otherwise the zone of the
  /// country's bundled cities is preselected if they all have the same one,
  /// such as Europe/Berlin for Germany. That also picks the only zone of a
  /// country.
  void _selectCountry(String? flag) {
    final country = _countriesByFlag[flag];
    if (country == null) return;
    final cityZones = [
      for (final zone in country.zones.values)
        if (zone.cities.isNotEmpty) zone.timeZone,
    ];
    final zone = country.zoneFor(_timeZone) ??
        (cityZones.length == 1 ? cityZones.single : null);
    setState(() {
      _country = country;
      _timeZone = zone;
    });
    final text = zone == null ? '' : timeZoneLabel(zone);
    if (_timeZoneController.text != text) _timeZoneController.text = text;
  }

  bool get _timeZoneFitsCountry =>
      _country != null && _country!.zones.containsKey(_timeZone);

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && _timeZoneFitsCountry;

  void _save() {
    final name = _nameController.text.trim();
    final country = _country!;
    final zone = country.zones[_timeZone]!;
    // The offset of a bundled city in the zone, else the zone's. The map
    // shows the city at the zone's principal location (Berlin for
    // Europe/Berlin), or at the first bundled city of a zone that zone.tab
    // lacks.
    final template = zone.cities.firstOrNull;
    Navigator.pop(
      context,
      City(
        name: name,
        country: country.name,
        timeZone: zone.timeZone,
        flag: country.flag,
        utc: template?.utc ?? listedUtcOffset(zone.timeZone),
        weatherZone: name,
        latitude: zone.countryZone?.latitude ?? template?.latitude,
        longitude: zone.countryZone?.longitude ?? template?.longitude,
        isCustom: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final country = _country;
    final appliesIn =
        _timeZoneFitsCountry ? country!.zones[_timeZone]!.comment : '';
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.add_location_alt_rounded),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              widget.editing == null ? l10n.addCustomCity : l10n.editCustomCity,
            ),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.cityName,
                prefixIcon: const Icon(Icons.location_city_rounded),
              ),
            ),
            const SizedBox(height: 8),
            DropdownMenu<String>(
              controller: _countryController,
              initialSelection: country?.flag,
              expandedInsets: EdgeInsets.zero,
              menuHeight: 300,
              enableFilter: true,
              requestFocusOnTap: true,
              inputDecorationTheme: _fieldStyle,
              label: Text(l10n.country),
              errorText:
                  _unknownCountry == null ? null : l10n.pickCountryFromList,
              leadingIcon: country == null
                  ? const Icon(Icons.public_rounded)
                  : Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'assets/flags/${country.flag}',
                        width: 24,
                      ),
                    ),
              filterCallback: (entries, query) => _filter(
                entries,
                query,
                (entry) => _countriesByFlag[entry.value]!.searchText,
              ),
              dropdownMenuEntries: [
                for (final country in _countries)
                  DropdownMenuEntry(
                    value: country.flag,
                    label: country.label,
                    leadingIcon: Image.asset(
                      'assets/flags/${country.flag}',
                      width: 28,
                    ),
                  ),
              ],
              onSelected: _selectCountry,
            ),
            const SizedBox(height: 8),
            DropdownMenu<String>(
              controller: _timeZoneController,
              initialSelection: _timeZone,
              enabled: country != null,
              expandedInsets: EdgeInsets.zero,
              menuHeight: 300,
              enableFilter: true,
              requestFocusOnTap: true,
              inputDecorationTheme: _fieldStyle,
              label: Text(l10n.ianaTimeZone),
              // Where a picked zone applies, so a preselected one is easy to
              // check.
              helperText: country == null
                  ? l10n.pickCountryFirst
                  : appliesIn.isEmpty
                      ? null
                      : appliesIn,
              errorText:
                  country != null && _timeZone != null && !_timeZoneFitsCountry
                      ? l10n.timeZoneNotInCountry
                      : null,
              leadingIcon: const Icon(Icons.schedule_rounded),
              filterCallback: (entries, query) => _filter(
                entries,
                query,
                (entry) => country!.zones[entry.value]!.searchText,
              ),
              dropdownMenuEntries: [
                for (final zone in country?.zones.values ?? const <_Zone>[])
                  DropdownMenuEntry(
                    value: zone.timeZone,
                    label: timeZoneLabel(zone.timeZone),
                    labelWidget: zone.comment.isEmpty
                        ? null
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(timeZoneLabel(zone.timeZone)),
                              Text(
                                zone.comment,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                  ),
              ],
              onSelected: (value) => setState(() => _timeZone = value),
            ),
            const SizedBox(height: 16),
            Text(l10n.customCityOfflineHint),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _canSave ? _save : null, child: Text(l10n.add)),
      ],
    );
  }
}
