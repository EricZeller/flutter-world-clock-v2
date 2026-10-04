import 'package:flutter/material.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/models/city.dart';

/// Selectable list entry; must be placed inside a `RadioGroup<City>`.
class CityTile extends StatelessWidget {
  const CityTile({
    super.key,
    required this.city,
    required this.onEdit,
    required this.onDelete,
  });

  final City city;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RadioListTile<City>(
      isThreeLine: true,
      value: city,
      title: Text(
        city.name,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
          "${city.country.isEmpty ? '' : '${city.country}, '}UTC${city.utc} \n${city.timeZone}"),
      secondary: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            child: city.flag.isEmpty
                ? const Icon(Icons.star_rounded)
                : Image.asset('assets/flags/${city.flag}'),
          ),
          if (city.isCustom)
            PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'edit') onEdit();
                if (action == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
              ],
            ),
        ],
      ),
    );
  }
}
