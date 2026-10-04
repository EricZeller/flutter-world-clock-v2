import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/theme/app_theme.dart';

/// SharedPreferences keys. They must stay stable so existing installs keep
/// their settings after an update.
class PrefKeys {
  static const themeMode = 'themeMode';
  static const use24hr = 'use24hr';
  static const showSeconds = 'showSeconds';
  static const showSecondsLocal = 'showSecondsLocal';
  static const showMoreInfo = 'spMoreInfo';
  static const useFahrenheit = 'useFahrenheit';
  static const useCustomColor = 'useCustomColor';
  static const customColor = 'customColor';
  static const colorIndex = 'colorIndex';
  static const wttrServer = 'wttrServer';
  static const widgetOpacity = 'widgetOpacity';
  static const widgetLayout = 'widgetLayout';
}

class SettingsProvider extends ChangeNotifier {
  static const defaultWttrServer = 'https://wttr.in';
  static const defaultColorIndex = 4; // indigo

  // Stored values of the theme mode, kept for compatibility with older versions.
  static const _themeModeNames = {
    ThemeMode.system: 'System',
    ThemeMode.dark: 'Dark',
    ThemeMode.light: 'Light',
  };

  ThemeMode _themeMode = ThemeMode.system;
  bool _use24hr = true;
  bool _showSeconds = true;
  bool _showSecondsLocal = false;
  bool _showMoreInfo = true;
  bool _useFahrenheit = false;
  bool _useCustomColor = false;
  Color _customColor = Colors.indigo;
  int _colorIndex = defaultColorIndex;
  String _wttrServer = defaultWttrServer;
  double _widgetOpacity = 0.8;
  String _widgetLayout = 'detailed'; // 'detailed' or 'compact'

  ThemeMode get themeMode => _themeMode;
  bool get use24hr => _use24hr;
  bool get showSeconds => _showSeconds;
  bool get showSecondsLocal => _showSecondsLocal;
  bool get showMoreInfo => _showMoreInfo;
  bool get useFahrenheit => _useFahrenheit;
  bool get useCustomColor => _useCustomColor;
  Color get customColor => _customColor;
  int get colorIndex => _colorIndex;
  String get wttrServer => _wttrServer;
  double get widgetOpacity => _widgetOpacity;
  String get widgetLayout => _widgetLayout;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedThemeMode = prefs.getString(PrefKeys.themeMode);
    _themeMode = _themeModeNames.entries
        .firstWhere(
          (entry) => entry.value == storedThemeMode,
          orElse: () => const MapEntry(ThemeMode.system, 'System'),
        )
        .key;
    _use24hr = prefs.getBool(PrefKeys.use24hr) ?? true;
    _showSeconds = prefs.getBool(PrefKeys.showSeconds) ?? true;
    _showSecondsLocal = prefs.getBool(PrefKeys.showSecondsLocal) ?? false;
    _showMoreInfo = prefs.getBool(PrefKeys.showMoreInfo) ?? true;
    _useFahrenheit = prefs.getBool(PrefKeys.useFahrenheit) ?? false;
    _useCustomColor = prefs.getBool(PrefKeys.useCustomColor) ?? false;
    _customColor =
        Color(prefs.getInt(PrefKeys.customColor) ?? Colors.indigo.toARGB32());
    final colorIndex = prefs.getInt(PrefKeys.colorIndex) ?? defaultColorIndex;
    _colorIndex = colorIndex >= 0 && colorIndex < materialColors.length
        ? colorIndex
        : defaultColorIndex;
    _wttrServer = prefs.getString(PrefKeys.wttrServer) ?? defaultWttrServer;
    _widgetOpacity = prefs.getDouble(PrefKeys.widgetOpacity) ?? 0.8;
    _widgetLayout = prefs.getString(PrefKeys.widgetLayout) ?? 'detailed';
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    _themeMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.themeMode, _themeModeNames[value]!);
  }

  Future<void> setUse24hr(bool value) =>
      _setBool(PrefKeys.use24hr, value, () => _use24hr = value);

  Future<void> setShowSeconds(bool value) =>
      _setBool(PrefKeys.showSeconds, value, () => _showSeconds = value);

  Future<void> setShowSecondsLocal(bool value) => _setBool(
      PrefKeys.showSecondsLocal, value, () => _showSecondsLocal = value);

  Future<void> setShowMoreInfo(bool value) =>
      _setBool(PrefKeys.showMoreInfo, value, () => _showMoreInfo = value);

  Future<void> setUseFahrenheit(bool value) =>
      _setBool(PrefKeys.useFahrenheit, value, () => _useFahrenheit = value);

  Future<void> setUseCustomColor(bool value) =>
      _setBool(PrefKeys.useCustomColor, value, () => _useCustomColor = value);

  /// Selects one of [materialColors] as seed color for the custom theme.
  Future<void> setColorIndex(int index) async {
    _colorIndex = index;
    _customColor = materialColors[index];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefKeys.colorIndex, index);
    await prefs.setInt(PrefKeys.customColor, _customColor.toARGB32());
  }

  Future<void> setWttrServer(String value) async {
    _wttrServer = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.wttrServer, value);
  }

  Future<void> setWidgetOpacity(double value) async {
    _widgetOpacity = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(PrefKeys.widgetOpacity, value);
  }

  Future<void> setWidgetLayout(String value) async {
    _widgetLayout = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.widgetLayout, value);
  }

  Future<void> _setBool(String key, bool value, VoidCallback apply) async {
    apply();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}
