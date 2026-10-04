import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/utils/city_sorting.dart';

class SortMenu extends StatelessWidget {
  const SortMenu({super.key, required this.onSelected});

  final ValueChanged<CitySort> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = {
      CitySort.city: (l10n.sortByCity, Icons.location_city_rounded),
      CitySort.country: (l10n.sortByCountry, Icons.flag_rounded),
      CitySort.utc: (l10n.sortByUtc, Icons.access_time_filled),
      CitySort.continent: (l10n.sortByContinent, Icons.public),
    };
    return PopupMenuButton<CitySort>(
      tooltip: l10n.sortList,
      onSelected: (sort) {
        HapticFeedback.lightImpact();
        onSelected(sort);
      },
      itemBuilder: (context) => [
        for (final MapEntry(key: sort, value: (label, icon)) in entries.entries)
          PopupMenuItem<CitySort>(
            value: sort,
            child: ListTile(
              leading: Icon(icon, semanticLabel: label),
              title: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
      icon: Icon(
        Icons.sort,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        semanticLabel: l10n.sortList,
      ),
    );
  }
}
