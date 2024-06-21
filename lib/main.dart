import 'dart:convert';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:world_clock_v2/pages/settings.dart';
import 'package:world_clock_v2/pages/location.dart';
import 'package:world_clock_v2/pages/about.dart';
import 'package:http/http.dart' as http;
import 'package:world_clock_v2/data/data.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:world_clock_v2/services/settings_provider.dart';

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
                ColorScheme.fromSeed(seedColor: settings.customColor).harmonized();
            darkColorScheme = ColorScheme.fromSeed(
                    seedColor: settings.customColor, brightness: Brightness.dark)
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
              '/home': (context) => const MyHomePage(title: "World clock v2"),
              '/about': (context) => const AboutPage(title: "About this app"),
              '/settings': (context) => const SettingsPage(title: "Settings"),
              '/location': (context) =>
                  const LocationPage(title: "Choose city"),
            },
          );
        });
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

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
      } catch (e) {
        // Fehlerbehandlung, wenn JSON nicht erfolgreich dekodiert werden kann
      }
    });
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
    });
  }

  @override
  void initState() {
    super.initState();
    getThemeModePreference();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (secondsElapsed == 30) {
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

  Future<void> getWeather(weatherZone) async {
    _weather = "🛰️ Loading...";
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('wttrServer') != null) {
      wttrServer = prefs.getString('wttrServer')!;
    }
    try {
      var response =
          await http.get(Uri.parse('$wttrServer/$weatherZone?format=%c+%C+%t'));
      if (response.statusCode == 200) {
        setState(() {
          _weather = response.body;
        });
      } else {
        setState(() {
          _weather = "🛜 Couldn't connect to API";
        });
      }
    } catch (e) {
      _weather = "🛜 Connection error";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String result) async {
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
              const PopupMenuItem<String>(
                value: 'settings',
                child: ListTile(
                  title: Text('Settings'),
                  leading: Icon(Icons.settings),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'changeCity',
                child: ListTile(
                  title: Text('Change city'),
                  leading: Icon(Icons.edit_location_alt),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'about',
                child: ListTile(
                  title: Text('About'),
                  leading: Icon(Icons.info),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'source_code',
                child: ListTile(
                  title: Text('Source Code'),
                  leading: Icon(Icons.code),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'bug_report',
                child: ListTile(
                  title: Text('Report a bug'),
                  leading: Icon(Icons.bug_report),
                ),
              ),
            ],
          )
        ],
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        title: Text(
          widget.title,
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
                        fontSize: 50.0,
                        fontFamily: "Pacifico",
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  getLocalTime(),
                  style: TextStyle(
                      fontSize: 30.0,
                      fontFamily: "Red Hat Display",
                      color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () async {
                await Navigator.pushNamed(context, '/location');
                getTimeZone();
              },
              label: Text(
                "Change city",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: "Red Hat Display",
                    color: Theme.of(context).colorScheme.primary),
              ),
              icon: Icon(Icons.edit_location_alt_outlined,
                  color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        onPressed: () => Navigator.pushNamed(
          context,
          '/settings',
        ),
        child: const Icon(Icons.settings),
      ),
    );
  }

  Future<void> _launchUrl(url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}
