import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  Color _customColor = Colors.indigo;
  bool _useCustomColor = false;
  double _widgetOpacity = 0.8;
  String _widgetLayout = 'detailed'; // 'detailed' or 'compact'

  Color get customColor => _customColor;
  bool get useCustomColor => _useCustomColor;
  double get widgetOpacity => _widgetOpacity;
  String get widgetLayout => _widgetLayout;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('customColor') ?? Colors.indigo.toARGB32();
    _customColor = Color(colorValue);
    _useCustomColor = prefs.getBool('useCustomColor') ?? false;
    _widgetOpacity = prefs.getDouble('widgetOpacity') ?? 0.8;
    _widgetLayout = prefs.getString('widgetLayout') ?? 'detailed';

    notifyListeners();
  }

  Future<void> setCustomColor(Color color) async {
    _customColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('customColor', color.toARGB32());
  }

  Future<void> setUseCustomColor(bool value) async {
    _useCustomColor = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useCustomColor', value);
  }

  Future<void> setWidgetOpacity(double value) async {
    _widgetOpacity = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('widgetOpacity', value);
  }

  Future<void> setWidgetLayout(String value) async {
    _widgetLayout = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('widgetLayout', value);
  }
}
