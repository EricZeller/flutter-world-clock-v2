import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  Color _customColor = Colors.indigo;
  bool _useCustomColor = false;

  Color get customColor => _customColor;
  bool get useCustomColor => _useCustomColor;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('customColor') ?? Colors.indigo.value;
    _customColor = Color(colorValue);
    _useCustomColor = prefs.getBool('useCustomColor') ?? false;

    notifyListeners();
  }

  Future<void> setCustomColor(Color color) async {
    _customColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('customColor', color.value);
  }

  Future<void> setUseCustomColor(bool value) async {
    _useCustomColor = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useCustomColor', value);
  }
}
