import 'dart:convert';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/data/data.dart';

class City {
  final String name;
  final String country;
  final String timeZone;
  final String flag;
  final String utc;
  final String weatherZone;

  City(
      {required this.name,
      required this.country,
      required this.timeZone,
      required this.flag,
      required this.utc,
      required this.weatherZone});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'country': country,
      'timeZone': timeZone,
      'flag': flag,
      'utc': utc,
      'weatherZone': weatherZone,
    };
  }

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'],
      country: json['country'],
      timeZone: json['timeZone'],
      flag: json['flag'],
      utc: json['utc'],
      weatherZone: json['weatherZone'],
    );
  }
}

Future<List<City>> loadCities() async {
  final String response =
      await rootBundle.loadString('assets/data/cities.json');
  final data = await json.decode(response) as List;
  return data.map((city) => City.fromJson(city)).toList();
}

class LocationPage extends StatefulWidget {
  const LocationPage({super.key, required this.title});

  final String title;

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  List<City> _cities = [];
  List<City> _filteredCities = [];
  late City _selectedOption;

  Future<void> getSelectedOption() async {
    _selectedOption = _cities.first;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.getString('selectedOption') != null) {
        var cityJson = jsonDecode(prefs.getString('selectedOption')!);
        _selectedOption = City.fromJson(cityJson);
      }
    });
  }

  Future<void> _saveStringValue(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  void _saveSelectedCity(String key, City city) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, jsonEncode(city.toJson()));
  }

  void _searchCities(String query) {
    final filtered = _cities.where((city) {
      return city.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredCities = filtered;
    });
  }

  @override
  void initState() {
    super.initState();
    loadCities().then((cities) {
      setState(() {
        _cities = cities;
        _filteredCities = cities;
        getSelectedOption();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(builder: (lightDynamic, darkDynamic) {
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
            title: Text(widget.title,
                style: TextStyle(
                    fontFamily: "Pacifico",
                    fontSize: 24,
                    color: Theme.of(context).colorScheme.onPrimaryContainer)),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                //print(_selectedOption);
                Navigator.pop(context, _selectedOption);
              },
            ),
          ),
          body: Column(
            children: [
              TextField(
                onChanged: (query) => _searchCities(query),
                decoration: InputDecoration(hintText: 'Search for a city'),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredCities.length,
                  itemBuilder: (context, index) {
                    return RadioListTile(
                      value: _filteredCities[index],
                      groupValue: _selectedOption,
                      onChanged: (value) {
                        setState(() {
                          _selectedOption = value!;
                          _saveSelectedCity('selectedOption', value);
                        });
                      },
                      title: Text(_filteredCities[index].name),
                      subtitle: Text(
                          "${_filteredCities[index].country}, UTC${_filteredCities[index].utc}"),
                    );
                  },

                  /*children: cities.map((city) {
                    return RadioListTile(
                      value: city.name,
                      groupValue: _selectedOption,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedOption = value!;
                          _saveStringValue('selectedOption', _selectedOption!);
                        });
                      },
                      tileColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      title: Text(
                        '${city.name}, ${city.country}',
                        style: const TextStyle(
                            fontFamily: 'Red Hat Display',
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      ),
                      subtitle: Text(city.timeZone),
                      secondary: ClipRRect(
                        child: Image.asset(
                          "assets/flags/${city.flag}",
                          width: 40,
                        ),
                      ),
                    );
                  }).toList(),*/
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.pop(context, _selectedOption),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
            child: const Icon(Icons.check),
          ),
        ),
      );
    });
  }
}
