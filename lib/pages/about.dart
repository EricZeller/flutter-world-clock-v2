import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:world_clock_v2/data/data.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:yaml/yaml.dart';

Future<String> getAppVersion() async {
  final pubspec = await rootBundle.loadString('pubspec.yaml');
  final yamlMap = loadYaml(pubspec);
  final version = yamlMap['version'] as String;
  final pureVersion = version.split('+').first; // Entfernt die Build-Nummer
  return pureVersion;
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getAppVersion(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final version = snapshot.data!;
        return Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return DynamicColorBuilder(builder: (lightDynamic, darkDynamic) {
              ColorScheme lightColorScheme;
              ColorScheme darkColorScheme;

              if (lightDynamic != null &&
                  darkDynamic != null &&
                  !useCustomColor) {
                lightColorScheme = lightDynamic.harmonized();
                darkColorScheme = darkDynamic.harmonized();
              } else {
                lightColorScheme =
                    ColorScheme.fromSeed(seedColor: settings.customColor)
                        .harmonized();
                darkColorScheme = ColorScheme.fromSeed(
                        seedColor: settings.customColor,
                        brightness: Brightness.dark)
                    .harmonized();
              }

              ThemeMode? themeModePreference;
              TextStyle heading = TextStyle(
                  fontFamily: "Pacifico",
                  fontSize: 24,
                  color: Theme.of(context).colorScheme.onSecondaryContainer);
              TextStyle body = TextStyle(
                  fontFamily: "Red Hat Display",
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSecondaryContainer);

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
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  appBar: AppBar(
                    centerTitle: true,
                    title: Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: "Red Hat Display",
                            fontSize: 24,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer)),
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  body: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("World Clock v2", style: heading),
                        Text("Current version: v$version",
                            style: TextStyle(
                                fontFamily: "Red Hat Display",
                                fontSize: 20,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer)),
                        const SizedBox(height: 20),
                        Text(
                            style: body,
                            "World Clock is a Flutter app that displays the current time and weather for various cities. The app uses the Material You theme to provide a modern and customizable user experience.\nCheck out the numerous settings for an even more personalized experience."),
                        Divider(
                          height: 60.0,
                          thickness: 2,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        Text("License", style: heading),
                        const SizedBox(height: 10),
                        Text(
                            style: body,
                            "This app is licensed under the GNU GPL 3.0. For more details, see the LICENSE file in the repository."),
                        Divider(
                          height: 60.0,
                          thickness: 2,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        Text("Contact", style: heading),
                        const SizedBox(height: 10),
                        Text(
                            style: body,
                            "If you have any questions or suggestions, feel free to contact me over GitHub or open an Issue over the repository of this app."),
                      ],
                    ),
                  ),
                ),
              );
            });
          },
        );
      },
    );
  }
}
