import 'package:colornames/colornames.dart';
import 'package:flutter/material.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';

class ColorPickerTile extends StatelessWidget {
  const ColorPickerTile({
    super.key,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  final List<Color> colors;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(AppLocalizations.of(context)!.selectColor),
      leading: Icon(Icons.format_color_fill_rounded, color: selectedColor),
      trailing: DropdownButton<Color>(
        value: selectedColor,
        items: colors.map((Color color) {
          return DropdownMenuItem<Color>(
            value: color,
            child: Row(
              children: [
                CircleAvatar(maxRadius: 10, backgroundColor: color),
                const SizedBox(width: 5),
                Text(colorName(color), style: const TextStyle(fontSize: 13)),
              ],
            ),
          );
        }).toList(),
        onChanged: (Color? newColor) {
          if (newColor != null) onColorSelected(newColor);
        },
      ),
    );
  }

  /// Short name for [color], limited to two words.
  static String colorName(Color color) {
    return ColorNames.guess(color).split(' ').take(2).join(' ');
  }
}
