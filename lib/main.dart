import 'dart:convert';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:world_clock_v2/pages/settings.dart';
import 'package:world_clock_v2/pages/location.dart';
import 'package:world_clock_v2/pages/about.dart';
import 'package:world_clock_v2/pages/widget_settings.dart';
import 'package:http/http.dart' as http;
import 'package:world_clock_v2/data/data.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:home_widget/home_widget.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';

void main() {
  tz.initializeTimeZones();
  runApp(
    ChangeNotifierProvider(
      create: (context) => SettingsProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return DynamicColorBuilder(builder: (lightDynamic, darkDynamic) {
          ColorScheme lightColorScheme;
          ColorScheme darkColorScheme;

          if (lightDynamic != null && darkDynamic != null && !useCustomColor) {
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
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              fontFamily: "Red Hat Display",
              colorScheme: lightColorScheme,
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              fontFamily: "Red Hat Display",
              colorScheme: darkColorScheme,
              useMaterial3: true,
            ),
            themeMode: themeModePreference,
            initialRoute: '/home',
            routes: {
              '/home': (context) => const MyHomePage(),
              '/about': (context) => const AboutPage(),
              '/settings': (context) => const SettingsPage(),
              '/widget_settings': (context) => const WidgetSettingsPage(),
              '/location': (context) =>
                  const LocationPage(),
            },
          );
        });
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Timer _timer;
  String _weather = "Loading...";
  String? cityName = "Berlin";
  String? timeZone = "Europe/Berlin";
  String cityWeatherZone = "Berlin";
  String country = "Germany";
  String utc = "+02:00";

  int secondsElapsed = 0;

  final Uri _githubUrl =
      Uri.parse('https://github.com/EricZeller/flutter-world-clock-v2');
  final Uri _issueUrl =
      Uri.parse('https://github.com/EricZeller/flutter-world-clock-v2/issues');

  Future<void> getTimeZone() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      cityName = prefs.getString('selectedOption');
      cityName ??= 'Berlin';
      try {
        var cityJson = jsonDecode(cityName!);
        City city = City.fromJson(cityJson);
        cityName = city.name;
        cityWeatherZone = city.weatherZone;
        timeZone = city.timeZone;
        country = city.country;
        utc = city.utc;
        getWeather(cityName);
        _updateHomeWidget();
      } catch (e) {
        // Fehlerbehandlung, wenn JSON nicht erfolgreich dekodiert werden kann
      }
    });
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0')}';
  }

  Future<void> _updateHomeWidget() async {
    try {
      if (cityName == null) return;
      
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      
      // Get colors from Theme
      final colorScheme = Theme.of(context).colorScheme;
      final bgColor = _colorToHex(colorScheme.primaryContainer);
      final primaryColor = _colorToHex(colorScheme.onPrimaryContainer);
      final secondaryColor = _colorToHex(colorScheme.primary);

      // We use a small delay to ensure that multiple calls to saveWidgetData 
      // are processed correctly by the plugin before triggering the update.
      await HomeWidget.saveWidgetData<String>('city', cityName);
      await HomeWidget.saveWidgetData<String>('weather', _weather);

      // Extract emoji from weather report (it's at the very beginning)
      String weatherIcon = "☀️";
      if (_weather.isNotEmpty) {
        final parts = _weather.trim().split(' ');
        if (parts.isNotEmpty) {
          weatherIcon = parts[0];
        }
      }
      await HomeWidget.saveWidgetData<String>('weather_icon', weatherIcon);

      await HomeWidget.saveWidgetData<String>('timeZone', timeZone);
      await HomeWidget.saveWidgetData<String>('bgColor', bgColor);
      await HomeWidget.saveWidgetData<String>('primaryColor', primaryColor);
      await HomeWidget.saveWidgetData<String>('secondaryColor', secondaryColor);
      
      // New Widget Settings
      await HomeWidget.saveWidgetData<String>(
        'widgetOpacity',
        settings.widgetOpacity.toString(),
      );
      await HomeWidget.saveWidgetData<String>('widgetLayout', settings.widgetLayout);
      await HomeWidget.saveWidgetData<bool>('use24hr', sp24hr);

      // Tiny delay to ensure SharedPreferences are flushed to disk
      await Future.delayed(const Duration(milliseconds: 100));

      await HomeWidget.updateWidget(
        name: 'WorldClockWidgetProvider',
        androidName: 'WorldClockWidgetProvider',
      );
    } catch (e) {
      debugPrint("Error updating home widget: $e");
    }
  }

  Future<void> getThemeModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.getString('themeMode') != null) {
        spThemeMode = prefs.getString('themeMode');
      }
    });
  }

  Future<void> getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.getBool('use24hr') != null) {
        sp24hr = prefs.getBool('use24hr')!;
      }
      if (prefs.getBool('showSeconds') != null) {
        showSeconds = prefs.getBool('showSeconds')!;
      }
      if (prefs.getBool('showSecondsLocal') != null) {
        showSecondsLocal = prefs.getBool('showSecondsLocal')!;
      }
      if (prefs.getBool('spMoreInfo') != null) {
        spMoreInfo = prefs.getBool('spMoreInfo')!;
      }
      if (prefs.getBool('useCustomColor') != null) {
        useCustomColor = prefs.getBool('useCustomColor')!;
      }
      if (prefs.getInt('colorIndex') != null) {
        colorIndex = prefs.getInt('colorIndex')!;
      }
      if (prefs.getBool('useFahrenheit') != null) {
        useFahrenheit = prefs.getBool('useFahrenheit')!;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    getThemeModePreference();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        // Update weather every 15 minutes (900 seconds)
        if (secondsElapsed >= 900) {
          getWeather(cityWeatherZone);
          secondsElapsed = 0;
        } else {
          secondsElapsed++;
        }
      });
    });
    getTimeZone();
    getPreferences();
    getWeather(cityWeatherZone);
    // Update widget after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateHomeWidget();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateHomeWidget();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String getTimeInTimeZone(String timeZone) {
    var now = tz.TZDateTime.now(tz.getLocation(timeZone));
    DateFormat formatter;

    if (showSeconds) {
      formatter = sp24hr ? DateFormat('Hms') : DateFormat('hh:mm:ss a');
    } else {
      formatter = sp24hr ? DateFormat('Hm') : DateFormat('hh:mm a');
    }

    return formatter.format(now);
  }

  String getLocalTime() {
    var now = DateTime.now();
    DateFormat formatter;

    if (showSecondsLocal) {
      formatter = sp24hr ? DateFormat('Hms') : DateFormat('hh:mm:ss a');
    } else {
      formatter = sp24hr ? DateFormat('Hm') : DateFormat('hh:mm a');
    }

    return "Local time: ${formatter.format(now)}";
  }

  String getTimeDifference() {
    final cityOffset = tz.TZDateTime.now(
      tz.getLocation(timeZone!),
    ).timeZoneOffset;
    final localOffset = DateTime.now().timeZoneOffset;
    final difference = cityOffset - localOffset;
    final totalMinutes = difference.inMinutes;
    final sign = totalMinutes < 0 ? '-' : '+';
    final absoluteMinutes = totalMinutes.abs();
    final hours = (absoluteMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (absoluteMinutes % 60).toString().padLeft(2, '0');
    return '$sign$hours:$minutes';
  }

  Future<void> getWeather(weatherZone) async {
    String requestURL;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('wttrServer') != null) {
      wttrServer = prefs.getString('wttrServer')!;
    }
    try {
      if (useFahrenheit) {
        requestURL = '$wttrServer/$weatherZone?format=%c+%C+%t&u';
      } else {
        requestURL = '$wttrServer/$weatherZone?format=%c+%C+%t';
      }
      var response = await http.get(Uri.parse(requestURL));
      if (response.statusCode == 200) {
        setState(() {
          _weather = response.body;
          _updateHomeWidget();
        });
      }
    } catch (e) {
      // Keep existing weather on error
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String result) async {
              HapticFeedback.lightImpact();
              switch (result) {
                case 'settings':
                  await Navigator.pushNamed(
                    context,
                    '/settings',
                  );
                  getWeather(cityWeatherZone);
                  break;
                case 'changeCity':
                  await Navigator.pushNamed(context, '/location');
                  getTimeZone();
                  break;
                case 'about':
                  Navigator.pushNamed(context, '/about');
                  break;
                case 'source_code':
                  _launchUrl(_githubUrl);
                  break;
                case 'bug_report':
                  _launchUrl(_issueUrl);
                  break;
              }
            },
            icon: const Icon(Icons.more_vert),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'settings',
                child: ListTile(
                  title: Text(l10n.settings),
                  leading: Icon(Icons.settings, semanticLabel: l10n.settings),
                ),
              ),
              PopupMenuItem<String>(
                value: 'changeCity',
                child: ListTile(
                  title: Text(l10n.changeCity),
                  leading: Icon(Icons.edit_location_alt, semanticLabel: l10n.changeCity),
                ),
              ),
              PopupMenuItem<String>(
                value: 'about',
                child: ListTile(
                  title: Text(l10n.about),
                  leading: Icon(Icons.info, semanticLabel: l10n.about),
                ),
              ),
              PopupMenuItem<String>(
                value: 'source_code',
                child: ListTile(
                  title: Text(l10n.sourceCode),
                  leading: Icon(Icons.code, semanticLabel: l10n.sourceCode),
                ),
              ),
              PopupMenuItem<String>(
                value: 'bug_report',
                child: ListTile(
                  title: Text(l10n.reportBug),
                  leading: Icon(Icons.bug_report, semanticLabel: l10n.reportBug),
                ),
              ),
            ],
          )
        ],
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        title: Text(
          l10n.appTitle,
          style: const TextStyle(fontFamily: "Red Hat Display"),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 40.0),
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
              child: SizedBox(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    cityName!,
                    style: TextStyle(
                        fontSize: 55.0,
                        fontFamily: 'Pacifico',
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10.0),
            Visibility(
              visible: spMoreInfo,
              child: Column(
                children: [
                  const SizedBox(height: 20.0),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "$country, UTC$utc",
                      style: TextStyle(
                          letterSpacing: 2,
                          fontSize: 18,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  getTimeInTimeZone(timeZone!),
                  style: TextStyle(
                    fontSize: 100.0,
                    fontFamily: "Red Hat Display",
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _weather,
                style: TextStyle(
                    fontSize: 20.0,
                    fontFamily: "Red Hat Display",
                    color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
            Divider(
              height: 80.0,
              thickness: 2,
              indent: 30,
              endIndent: 30,
              color: Theme.of(context).colorScheme.primary,
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.localTime(getLocalTime().replaceAll("Local time: ", "")),
                  style: TextStyle(
                      fontSize: 30.0,
                      fontFamily: "Red Hat Display",
                      color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 6),
                Tooltip(
                  message: 'Difference to local time',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.compare_arrows_rounded,
                        size: 17,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Δ ${getTimeDifference()}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () async {
                HapticFeedback.lightImpact();
                await Navigator.pushNamed(context, '/location');
                getTimeZone();
              },
              label: Text(
                l10n.changeCity,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: "Red Hat Display",
                    color: Theme.of(context).colorScheme.primary),
              ),
              icon: Icon(Icons.edit_location_alt_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  semanticLabel: l10n.changeCity),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(
            context,
            '/settings',
          );
        },
        child: Icon(Icons.settings, semanticLabel: l10n.settings),
      ),
    );
  }

  Future<void> _launchUrl(url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}
