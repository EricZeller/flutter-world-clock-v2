import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

/// Seed colors the user can choose from for the custom theme.
final List<MaterialColor> materialColors = [
  Colors.red,
  Colors.pink,
  Colors.purple,
  Colors.deepPurple,
  Colors.indigo,
  Colors.blue,
  Colors.lightBlue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.lightGreen,
  Colors.lime,
  Colors.yellow,
  Colors.amber,
  Colors.orange,
  Colors.deepOrange,
  Colors.brown,
  Colors.grey,
  Colors.blueGrey,
];

class AppTheme {
  static const fontFamily = 'Red Hat Display';
  static const accentFontFamily = 'Pacifico';

  /// Uses the Material You colors of the device unless the user picked a
  /// custom color or the platform has no dynamic colors.
  static ColorScheme colorScheme({
    required Brightness brightness,
    required ColorScheme? dynamicScheme,
    required bool useCustomColor,
    required Color seedColor,
  }) {
    if (dynamicScheme != null && !useCustomColor) {
      return dynamicScheme.harmonized();
    }
    return ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness)
        .harmonized();
  }

  static ThemeData themeData(ColorScheme colorScheme) {
    return ThemeData(
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      useMaterial3: true,
    );
  }
}
