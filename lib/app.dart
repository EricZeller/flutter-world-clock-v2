import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/pages/about.dart';
import 'package:world_clock_v2/pages/home/home_page.dart';
import 'package:world_clock_v2/pages/location/location_page.dart';
import 'package:world_clock_v2/pages/settings/settings_page.dart';
import 'package:world_clock_v2/pages/widget_settings.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:world_clock_v2/theme/app_theme.dart';

class WorldClockApp extends StatelessWidget {
  const WorldClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return DynamicColorBuilder(builder: (lightDynamic, darkDynamic) {
      ColorScheme scheme(Brightness brightness, ColorScheme? dynamicScheme) {
        return AppTheme.colorScheme(
          brightness: brightness,
          dynamicScheme: dynamicScheme,
          useCustomColor: settings.useCustomColor,
          seedColor: settings.customColor,
        );
      }

      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'World clock',
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.themeData(scheme(Brightness.light, lightDynamic)),
        darkTheme: AppTheme.themeData(scheme(Brightness.dark, darkDynamic)),
        themeMode: settings.themeMode,
        initialRoute: '/home',
        routes: {
          '/home': (context) => const HomePage(),
          '/about': (context) => const AboutPage(),
          '/settings': (context) => const SettingsPage(),
          '/widget_settings': (context) => const WidgetSettingsPage(),
          '/location': (context) => const LocationPage(),
        },
      );
    });
  }
}
