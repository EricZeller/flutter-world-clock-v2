import 'package:flutter/material.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/models/city.dart';

String _cityDetails(City city) =>
    "${city.country.isEmpty ? '' : '${city.country}, '}UTC${city.utc}";

Widget _flag(City city) => SizedBox(
      width: 40,
      child: city.flag.isEmpty
          ? const Icon(Icons.star_rounded)
          : Image.asset('assets/flags/${city.flag}'),
    );

/// List entry of the city list; the check box adds it to the favorites.
class CityTile extends StatelessWidget {
  const CityTile({
    super.key,
    required this.city,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onEdit,
    required this.onDelete,
  });

  final City city;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CheckboxListTile(
      isThreeLine: true,
      controlAffinity: ListTileControlAffinity.leading,
      value: isFavorite,
      onChanged: (_) => onToggleFavorite(),
      title: Text(
        city.name,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      subtitle: Text('${_cityDetails(city)} \n${city.timeZone}'),
      secondary: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _flag(city),
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

/// Entry of the favorites; must be placed in a reorderable list at [index].
class FavoriteTile extends StatelessWidget {
  const FavoriteTile({
    super.key,
    required this.city,
    required this.index,
    required this.onRemove,
  });

  final City city;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: _flag(city),
        title: Text(
          city.name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_cityDetails(city)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.removeFromFavorites,
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: onRemove,
            ),
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.drag_handle, semanticLabel: l10n.reorderCity),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
