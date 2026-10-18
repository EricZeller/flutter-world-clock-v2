import 'package:flutter/material.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/models/city.dart';

/// Shows a dialog to create a custom city, or edit [editing] if given.
/// The available countries, flags, time zones and coordinates are taken from
/// the bundled cities among [cities].
Future<City?> showCustomCityDialog(
  BuildContext context, {
  required List<City> cities,
  City? editing,
}) {
  return showDialog<City>(
    context: context,
    builder: (context) => CustomCityDialog(cities: cities, editing: editing),
  );
}

/// A country of the bundled cities, identified by its flag: the flags are
/// named by ISO code, so Hong Kong stays apart from the rest of China
/// although the cities of both name China as their country.
class _Country {
  _Country(this.flag, this.name);

  final String flag;
  final String name;
  final cities = <City>[];

  /// The name, followed by the cities if another flag has the same name.
  late final String label;

  /// The time zones of [cities], sorted.
  late final List<String> timeZones;

  /// Everything the country can be found by: its label and its cities.
  late final String searchText;

  /// Everything each of [timeZones] can be found by: its label and the
  /// cities of this country in it.
  late final Map<String, String> timeZoneSearchText;
}

class CustomCityDialog extends StatefulWidget {
  const CustomCityDialog({super.key, required this.cities, this.editing});

  final List<City> cities;
  final City? editing;

  @override
  State<CustomCityDialog> createState() => _CustomCityDialogState();
}

class _CustomCityDialogState extends State<CustomCityDialog> {
  late final TextEditingController _nameController;
  final _countryController = TextEditingController();
  final _timeZoneController = TextEditingController();
  late final List<_Country> _countries;
  late final Map<String, _Country> _countriesByFlag;
  _Country? _country;
  String? _timeZone;

  /// The country of an edited city that is none of [_countries]; shown as an
  /// error until another country is picked or typed.
  String? _unknownCountry;

  @override
  void initState() {
    super.initState();
    _countries = _countriesOf(widget.cities);
    _countriesByFlag = {
      for (final country in _countries) country.flag: country,
    };

    final editing = widget.editing;
    _nameController = TextEditingController(text: editing?.name);
    if (editing != null) {
      _country = _matchCountry(editing);
      final country = editing.country.trim();
      if (_country != null) {
        _countryController.text = _country!.label;
      } else if (country.isNotEmpty) {
        _countryController.text = _unknownCountry = country;
      }
      // Shown even if it is no zone of the country, so it can be fixed.
      _timeZone = editing.timeZone;
      _timeZoneController.text = timeZoneLabel(editing.timeZone);
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

  /// The countries of the bundled [cities], sorted by label. Custom cities
  /// are left out: they may spell their country differently.
  static List<_Country> _countriesOf(List<City> cities) {
    final byFlag = <String, _Country>{};
    for (final city in cities) {
      if (city.isCustom || city.flag.isEmpty) continue;
      final country = byFlag[city.flag] ??= _Country(city.flag, city.country);
      country.cities.add(city);
    }
    final flagsPerName = <String, int>{};
    for (final country in byFlag.values) {
      flagsPerName.update(
        country.name,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    for (final country in byFlag.values) {
      final cityNames = country.cities.map((city) => city.name);
      country
        ..label = flagsPerName[country.name]! > 1
            ? '${country.name} (${cityNames.join(', ')})'
            : country.name
        ..timeZones =
            (country.cities.map((city) => city.timeZone).toSet().toList()
              ..sort())
        ..searchText = [country.label, ...cityNames].join(' ').toLowerCase()
        ..timeZoneSearchText = {
          for (final zone in country.timeZones)
            zone: [
              timeZoneLabel(zone),
              for (final city in country.cities)
                if (city.timeZone == zone) city.name,
            ].join(' ').toLowerCase(),
        };
    }
    return byFlag.values.toList()
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  }

  /// The country [city] was saved with. Cities of older versions could
  /// combine any flag, country name and time zone, so the flag and the name
  /// are both tried, preferring a country that has the city's time zone and
  /// then the flag. A city without country and without a known flag gets the
  /// only country of its zone.
  _Country? _matchCountry(City city) {
    bool hasZone(_Country country) => country.timeZones.contains(city.timeZone);
    final name = city.country.trim().toLowerCase();
    if (name.isEmpty && !_countriesByFlag.containsKey(city.flag)) {
      final withZone = _countries.where(hasZone);
      return withZone.length == 1 ? withZone.single : null;
    }
    final candidates = _countries.where((country) =>
        country.flag == city.flag || country.name.toLowerCase() == name);
    return candidates.where(hasZone).firstOrNull ??
        _countriesByFlag[city.flag] ??
        candidates.firstOrNull;
  }

  // Underlined like the text field above instead of the outlined default.
  static const _fieldStyle = InputDecorationThemeData(
    border: UnderlineInputBorder(),
    contentPadding: EdgeInsets.symmetric(vertical: 12),
  );

  /// `America/New_York` reads better and is easier to find as
  /// `America/New York`.
  static String timeZoneLabel(String zone) => zone.replaceAll('_', ' ');

  static List<DropdownMenuEntry<String>> _filter(
    List<DropdownMenuEntry<String>> entries,
    String query,
    String Function(DropdownMenuEntry<String> entry) searchText,
  ) {
    // Underscores as in the IANA id `America/New_York` match the label.
    final words = query
        .toLowerCase()
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty);
    return entries
        .where((entry) => words.every(searchText(entry).contains))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _timeZoneController.dispose();
    super.dispose();
  }

  /// Picks the country of [flag] and keeps the time zone only if it is one
  /// of the country's; the only zone of a country is picked with it.
  void _selectCountry(String? flag) {
    final country = _countriesByFlag[flag];
    if (country == null) return;
    final zones = country.timeZones;
    final zone = zones.length == 1
        ? zones.single
        : zones.contains(_timeZone)
            ? _timeZone
            : null;
    setState(() {
      _country = country;
      _timeZone = zone;
    });
    final text = zone == null ? '' : timeZoneLabel(zone);
    if (_timeZoneController.text != text) _timeZoneController.text = text;
  }

  bool get _timeZoneFitsCountry =>
      _country != null && _country!.timeZones.contains(_timeZone);

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && _timeZoneFitsCountry;

  void _save() {
    final name = _nameController.text.trim();
    final country = _country!;
    final template = country.cities.firstWhere(
      (city) => city.timeZone == _timeZone,
    );
    Navigator.pop(
      context,
      City(
        name: name,
        country: country.name,
        timeZone: _timeZone!,
        flag: country.flag,
        utc: template.utc,
        weatherZone: name,
        latitude: template.latitude,
        longitude: template.longitude,
        isCustom: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final country = _country;
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
              helperText: country == null ? l10n.pickCountryFirst : null,
              errorText:
                  country != null && _timeZone != null && !_timeZoneFitsCountry
                      ? l10n.timeZoneNotInCountry
                      : null,
              leadingIcon: const Icon(Icons.schedule_rounded),
              filterCallback: (entries, query) => _filter(
                entries,
                query,
                (entry) => country!.timeZoneSearchText[entry.value]!,
              ),
              dropdownMenuEntries: [
                for (final zone in country?.timeZones ?? const <String>[])
                  DropdownMenuEntry(value: zone, label: timeZoneLabel(zone)),
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
