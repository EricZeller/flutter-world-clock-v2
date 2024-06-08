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

  Future<City> getSelectedOption() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('selectedOption') == null) {
      return _cities.first;
    } else {
      var cityJson = jsonDecode(prefs.getString('selectedOption')!);
      return City.fromJson(cityJson);
    }
  }


  void _saveSelectedCity(String key, City city) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, jsonEncode(city.toJson()));
  }

  void _searchCities(String query) {
    final filtered = _cities.where((city) {
      final cityName = city.name.toLowerCase();
      final cityCountry = city.country.toLowerCase();
      final searchQuery = query.toLowerCase();

      return cityName.contains(searchQuery) ||
          cityCountry.contains(searchQuery);
    }).toList();

    setState(() {
      _filteredCities = filtered;
    });
  }

  void sortCities(sorting) {
    setState(() {
      switch (sorting) {
        case "sortByCity":
          _filteredCities.sort((a, b) => a.name.compareTo(b.name));
          break;
        case "sortByCountry":
          _filteredCities.sort((a, b) => a.country.compareTo(b.country));
          break;
        case "sortByUtc":
          _filteredCities.sort((a, b) => compareUtc(a.utc, b.utc));
          break;
        case "sortByContinent":
          //_filteredCities.sort((a, b) => a.name.compareTo(b.name));
          _filteredCities.sort((a, b) => a.timeZone.compareTo(b.timeZone));
          break;
      }
    });
  }

  int compareUtc(String utc1, String utc2) {
    final regex = RegExp(r'([+-])(\d{2}):(\d{2})');

    final match1 = regex.firstMatch(utc1);
    final match2 = regex.firstMatch(utc2);

    if (match1 == null || match2 == null) {
      throw const FormatException('Invalid UTC format');
    }

    final sign1 = match1.group(1)!;
    final sign2 = match2.group(1)!;

    final hours1 = int.parse(match1.group(2)!);
    final minutes1 = int.parse(match1.group(3)!);
    final totalMinutes1 = hours1 * 60 + minutes1;

    final hours2 = int.parse(match2.group(2)!);
    final minutes2 = int.parse(match2.group(3)!);
    final totalMinutes2 = hours2 * 60 + minutes2;

    if (sign1 == '-' && sign2 == '-') {
      return totalMinutes2
          .compareTo(totalMinutes1); // Reverse order for negative times
    } else if (sign1 == '+' && sign2 == '+') {
      return totalMinutes1
          .compareTo(totalMinutes2); // Normal order for positive times
    } else {
      // '-' should come before '+'
      return sign1 == '-' ? -1 : 1;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeCitiesAndSelection();
  }

  Future<void> _initializeCitiesAndSelection() async {
    final cities = await loadCities();
    setState(() {
      _cities = cities;
      _filteredCities = cities;
    });

    final selectedOption = await getSelectedOption();
    setState(() {
      _selectedOption = selectedOption;
    });
    setState(() {
      sortCities("sortByCity");
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
            actions: [
              PopupMenuButton<String>(
                tooltip: "Sort the list",
                onSelected: (sorting) {
                  // Hier kannst du die entsprechende Sortierlogik basierend auf dem ausgewählten Wert implementieren
                  sortCities(sorting);
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'sortByCity',
                    child: Text('Sort by city'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'sortByCountry',
                    child: Text('Sort by country'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'sortByUtc',
                    child: Text('Sort by UTC timezone'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'sortByContinent',
                    child: Text('Sort by continent/region'),
                  ),
                  // Füge weitere Sortieroptionen hinzu, falls nötig
                ],
                icon: const Icon(Icons.sort),
              ),
            ],
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
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: TextField(
                  onChanged: (query) => _searchCities(query),
                  decoration: const InputDecoration(
                    hintText: 'Search city or country',
                    suffixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredCities.length,
                  itemBuilder: (context, index) {
                    return RadioListTile(
                      isThreeLine: true,
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
                          "${_filteredCities[index].country}, UTC${_filteredCities[index].utc} \n${_filteredCities[index].timeZone}"),
                      secondary: SizedBox(
                        width: 40,
                        child: ClipRRect(
                          child: Center(
                            child: Image.asset(
                              "assets/flags/${_filteredCities[index].flag}",
                            ),
                          ),
                        ),
                      ),
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
