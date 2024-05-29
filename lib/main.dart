import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:intl/intl_standalone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:world_clock_v2/pages/settings.dart';
import 'package:world_clock_v2/pages/location.dart';
import 'package:world_clock_v2/pages/about.dart';
import 'package:http/http.dart' as http;
import 'package:world_clock_v2/data/cities.dart';

void main() {
  tz.initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static final _defaultLightColorScheme =
      ColorScheme.fromSwatch(primarySwatch: Colors.blue);

  static final _defaultDarkColorScheme = ColorScheme.fromSwatch(
      primarySwatch: Colors.blue, brightness: Brightness.dark);

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'World clock',
        theme: ThemeData(
          colorScheme: lightColorScheme ?? _defaultLightColorScheme,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: darkColorScheme ?? _defaultDarkColorScheme,
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        initialRoute: '/home',
        routes: {
          '/home': (context) => MyHomePage(title: "World clock v2"),
          '/about': (context) => AboutPage(title: "About this app"),
          '/settings': (context) => SettingsPage(title: "Settings"),
          '/location': (context) => LocationPage(title: "Choose city"),
        },
      );
    });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Timer _timer;
  String _weather = "Loading...";

  @override
  void initState() {
    super.initState();
  }

  Future<void> getWeather(city) async {
    try {
      var response =
          await http.get(Uri.parse('https://wttr.in/$city?format=%c+%C+%t'));
      if (response.statusCode == 200) {
        setState(() {
          _weather = response.body;
        });
      } else {
        setState(() {
          _weather = "No weather data";
        });
      }
    } catch (e) {
      _weather = "Connection error";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String result) {
              switch (result) {
                case 'settings':
                  Navigator.pushNamed(context, '/settings');
                  break;
                case 'about':
                  Navigator.pushNamed(context, '/about');
                  break;
                case 'source_code':
                  //link to github
                  break;
              }
            },
            icon: Icon(Icons.more_vert),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'settings',
                child: Text('Settings'),
              ),
              const PopupMenuItem<String>(
                value: 'about',
                child: Text('About'),
              ),
              const PopupMenuItem<String>(
                value: 'source_code',
                child: Text('Source Code'),
              ),
            ],
          )
        ],
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        title: Text(
          widget.title,
          style: TextStyle(fontFamily: "Red Hat Display"),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 40.0),
            Text(
              "Berlin",
              style: TextStyle(
                  fontSize: 50.0,
                  fontFamily: "Pacifico",
                  color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            SizedBox(height: 20.0),
            Text(
              "18:10:43",
              style: TextStyle(
                  fontSize: 80.0,
                  fontFamily: "Red Hat Display",
                  color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            SizedBox(height: 20.0),
            Text(
              _weather,
              style: TextStyle(
                  fontSize: 20.0,
                  fontFamily: "Red Hat Display",
                  color: Theme.of(context).colorScheme.onPrimaryContainer),
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
                  "Local time: 19:10:43",
                  style: TextStyle(
                      fontSize: 30.0,
                      fontFamily: "Red Hat Display",
                      color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
            SizedBox(height: 20),
            TextButton.icon(
              onPressed: () async {
                final result =
                    await Navigator.pushNamed(context, '/location');
                if (result != null) {
                  setState(() {
                    try {
                      String cityNameToFind = result.toString();
                      City city = cities
                          .firstWhere((city) => city.name == cityNameToFind);
                      print(
                          'Gefundene Stadt: ${city.name}, Zeitzone: ${city.timeZone}, Bild: ${city.image}');
                    } catch (e) {
                      print('Stadt nicht gefunden');
                    }
                    print(result);
                    getWeather(result);
                  });
                }
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
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        onPressed: () {},
        tooltip: 'Reload',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
