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
  late final List<String> _timeZones;
  late final Map<String, String> _countries;
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
    _countries = {
      for (final city in widget.cities)
        if (city.flag.isNotEmpty) city.flag: city.country,
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
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
            DropdownButtonFormField<String>(
              initialValue: _flag,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.flagOptional,
                prefixIcon: const Icon(Icons.flag_rounded),
              ),
              items: _countries.entries
                  .map((entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Row(
                          children: [
                            Image.asset('assets/flags/${entry.key}', width: 28),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(entry.value,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _flag = value),
            ),
            DropdownButtonFormField<String>(
              initialValue: _timeZone,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.ianaTimeZone,
                prefixIcon: const Icon(Icons.schedule_rounded),
              ),
              items: _timeZones
                  .map((zone) =>
                      DropdownMenuItem(value: zone, child: Text(zone)))
                  .toList(),
              onChanged: (value) => setState(() => _timeZone = value),
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
