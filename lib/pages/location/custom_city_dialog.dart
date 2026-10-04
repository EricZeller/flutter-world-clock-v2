import 'package:flutter/material.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/models/city.dart';

/// Shows a dialog to create a custom city, or edit [editing] if given.
/// The available time zones, flags and coordinates are taken from [cities].
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

class CustomCityDialog extends StatefulWidget {
  const CustomCityDialog({super.key, required this.cities, this.editing});

  final List<City> cities;
  final City? editing;

  @override
  State<CustomCityDialog> createState() => _CustomCityDialogState();
}

class _CustomCityDialogState extends State<CustomCityDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _countryController;
  final _flagController = TextEditingController();
  final _timeZoneController = TextEditingController();
  late final List<String> _timeZones;
  late final Map<String, String> _countries;
  // Everything a time zone can be found by: its name and its cities.
  late final Map<String, String> _timeZoneSearchText;
  String? _timeZone;
  String? _flag;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _nameController = TextEditingController(text: editing?.name);
    _countryController = TextEditingController(text: editing?.country);
    _timeZone = editing?.timeZone;
    _flag = editing == null || editing.flag.isEmpty ? null : editing.flag;
    _timeZones = widget.cities.map((city) => city.timeZone).toSet().toList()
      ..sort();
    // Only bundled cities: custom ones may spell their country differently.
    _countries = Map.fromEntries([
      for (final city in widget.cities)
        if (city.flag.isNotEmpty && !city.isCustom)
          MapEntry(city.flag, city.country),
    ]..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase())));
    final searchText = <String, StringBuffer>{};
    for (final city in widget.cities) {
      (searchText[city.timeZone] ??= StringBuffer(timeZoneLabel(city.timeZone)))
        ..write(' ${city.name}')
        ..write(' ${city.country}');
    }
    _timeZoneSearchText = {
      for (final MapEntry(:key, :value) in searchText.entries)
        key: value.toString().toLowerCase(),
    };

    // A typed search that was not confirmed by picking an entry must not
    // keep the previous selection; clearing the text removes the flag.
    _flagController.addListener(() {
      if (_flag != null && _flagController.text != _countries[_flag]) {
        setState(() => _flag = null);
      }
    });
    _timeZoneController.addListener(() {
      if (_timeZone != null &&
          _timeZoneController.text != timeZoneLabel(_timeZone!)) {
        setState(() => _timeZone = null);
      }
    });
  }

  // Underlined like the text fields above instead of the outlined default.
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
    _flagController.dispose();
    _timeZoneController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && _timeZone != null;

  void _save() {
    final name = _nameController.text.trim();
    final template =
        widget.cities.firstWhere((city) => city.timeZone == _timeZone);
    Navigator.pop(
      context,
      City(
        name: name,
        country: _countryController.text.trim(),
        timeZone: _timeZone!,
        flag: _flag ?? '',
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
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.add_location_alt_rounded),
          const SizedBox(width: 12),
          Flexible(
            child: Text(widget.editing == null
                ? l10n.addCustomCity
                : l10n.editCustomCity),
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
            TextField(
              controller: _countryController,
              decoration: InputDecoration(
                labelText: l10n.countryOptional,
                prefixIcon: const Icon(Icons.public_rounded),
              ),
            ),
            const SizedBox(height: 8),
            DropdownMenu<String>(
              controller: _flagController,
              initialSelection: _flag,
              expandedInsets: EdgeInsets.zero,
              menuHeight: 300,
              enableFilter: true,
              requestFocusOnTap: true,
              inputDecorationTheme: _fieldStyle,
              label: Text(l10n.flagOptional),
              leadingIcon: _flag == null
                  ? const Icon(Icons.flag_rounded)
                  : Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset('assets/flags/$_flag', width: 24),
                    ),
              filterCallback: (entries, query) => _filter(
                  entries, query, (entry) => entry.label.toLowerCase()),
              dropdownMenuEntries: [
                for (final MapEntry(key: flag, value: country)
                    in _countries.entries)
                  DropdownMenuEntry(
                    value: flag,
                    label: country,
                    leadingIcon: Image.asset('assets/flags/$flag', width: 28),
                  ),
              ],
              onSelected: (value) => setState(() => _flag = value),
            ),
            const SizedBox(height: 8),
            DropdownMenu<String>(
              controller: _timeZoneController,
              initialSelection: _timeZone,
              expandedInsets: EdgeInsets.zero,
              menuHeight: 300,
              enableFilter: true,
              requestFocusOnTap: true,
              inputDecorationTheme: _fieldStyle,
              label: Text(l10n.ianaTimeZone),
              leadingIcon: const Icon(Icons.schedule_rounded),
              filterCallback: (entries, query) => _filter(
                  entries, query, (entry) => _timeZoneSearchText[entry.value]!),
              dropdownMenuEntries: [
                for (final zone in _timeZones)
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
        FilledButton(
          onPressed: _canSave ? _save : null,
          child: Text(l10n.add),
        ),
      ],
    );
  }
}
