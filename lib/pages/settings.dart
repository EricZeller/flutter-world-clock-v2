import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:world_clock_v2/data/data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.title});

  final String title;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String dropdownValue = themeList.first;

  Future<void> _saveStringValue(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> getThemeModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.getString('themeMode') != null) {
        spThemeMode = prefs.getString('themeMode');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    getThemeModePreference();
    dropdownValue = spThemeMode!;
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          lightColorScheme =
              ColorScheme.fromSeed(seedColor: Colors.indigo).harmonized();
          darkColorScheme = ColorScheme.fromSeed(
                  seedColor: Colors.indigo, brightness: Brightness.dark)
              .harmonized();
        }

        ThemeMode? themeModePreference;

        if (spThemeMode == themeList[0]) {
          themeModePreference = ThemeMode.system;
        } else if (spThemeMode == themeList[1]) {
          themeModePreference = ThemeMode.dark;
        } else if (spThemeMode == themeList[2]) {
          themeModePreference = ThemeMode.light;
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'World clock',
          theme: ThemeData(
            colorScheme: lightColorScheme,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
            useMaterial3: true,
          ),
          themeMode: themeModePreference,
          home: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: Text(
                widget.title,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Column(
              children: [
                ListTile(
                  title: const Text("Default theme"),
                  subtitle: const Text("Restart app to apply"),
                  leading: Icon(Icons.color_lens),
                  trailing: DropdownButton(
                    value: dropdownValue,
                    onChanged: (String? value) {
                      setState(() {
                        dropdownValue = value!;
                        spThemeMode = dropdownValue;
                        _saveStringValue('themeMode', spThemeMode!);
                      });
                    },
                    items:
                        themeList.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                ListTile(
                  title: const Text("Language"),
                  subtitle: const Text("In progress"),
                  leading: const Icon(Icons.language),
                  trailing: Text(spLanguage),
                )
              ],
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              onPressed: () => Navigator.pop(context),
              child: const Icon(Icons.check),
            ),
          ),
        );
      },
    );
  }
}
