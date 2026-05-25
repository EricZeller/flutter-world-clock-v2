import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:yaml/yaml.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';

Future<String> getAppVersion() async {
  final pubspec = await rootBundle.loadString('pubspec.yaml');
  final yamlMap = loadYaml(pubspec);
  final version = yamlMap['version'] as String;
  final pureVersion = version.split('+').first; // Entfernt die Build-Nummer
  return pureVersion;
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                    title: Text(l10n.aboutThisApp,
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
                      icon: Icon(Icons.arrow_back, semanticLabel: l10n.ok),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  body: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.appTitle, style: heading),
                          Text(l10n.currentVersion(version),
                              style: TextStyle(
                                  fontFamily: "Red Hat Display",
                                  fontSize: 20,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer)),
                          const SizedBox(height: 20),
                          Text(
                              style: body,
                              l10n.aboutDescription),
                          Divider(
                            height: 60.0,
                            thickness: 2,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          Text(l10n.license, style: heading),
                          const SizedBox(height: 10),
                          Text(
                              style: body,
                              l10n.licenseDescription),
                          Divider(
                            height: 60.0,
                            thickness: 2,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          Text(l10n.contact, style: heading),
                          const SizedBox(height: 10),
                          Text(
                              style: body,
                              l10n.contactDescription),
                        ],
                      ),
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
