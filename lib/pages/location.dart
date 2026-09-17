import 'dart:convert';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/data/data.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/widgets/world_map.dart';

class City {
  final String name;
  final String country;
  final String timeZone;
  final String flag;
  final String utc;
  final String weatherZone;
  final double? latitude;
  final double? longitude;
  final bool isCustom;

  City(
      {required this.name,
      required this.country,
      required this.timeZone,
      required this.flag,
      required this.utc,
      required this.weatherZone,
      this.latitude,
      this.longitude,
      this.isCustom = false});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'country': country,
      'timeZone': timeZone,
      'flag': flag,
      'utc': utc,
      'weatherZone': weatherZone,
      'latitude': latitude,
      'longitude': longitude,
      'isCustom': isCustom,
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
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isCustom: json['isCustom'] == true,
    );
  }
}

Future<List<City>> loadCities() async {
  final String response =
      await rootBundle.loadString('assets/data/cities.json');
  final data = await json.decode(response) as List;
  final cities = data.map((city) => City.fromJson(city)).toList();
  final prefs = await SharedPreferences.getInstance();
  final custom = prefs.getString('customCities');
  if (custom != null) {
    final customData = (jsonDecode(custom) as List)
        .map((city) => City.fromJson(city as Map<String, dynamic>));
    cities.addAll(customData);
  }
  return cities;
}

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  List<City> _cities = [];
  List<City> _filteredCities = [];
  bool _showMap = false;
  City _selectedOption = City(
      name: "Berlin",
      country: "Germany",
      timeZone: "Europe/Berlin",
      flag: "de.png",
      utc: "+02:00",
      weatherZone: "Berlin");

  Future<City> getSelectedOption() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('selectedOption') == null) {
      return _cities.first;
    } else {
      var cityJson = jsonDecode(prefs.getString('selectedOption')!);
      return City.fromJson(cityJson);
    }
  }

  Future<void> _saveSelectedCity(String key, City city) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, jsonEncode(city.toJson()));
  }

  Future<void> _addCustomCity({City? editing}) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: editing?.name);
    final countryController = TextEditingController(text: editing?.country);
    String? selectedTimeZone = editing?.timeZone;
    String? selectedFlag = editing?.flag.isEmpty == true ? null : editing?.flag;
    final timeZones = _cities.map((city) => city.timeZone).toSet().toList()..sort();
    final countries = <String, String>{
      for (final city in _cities)
        if (city.flag.isNotEmpty) city.flag: city.country,
    };

    final city = await showDialog<City>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.add_location_alt_rounded),
              SizedBox(width: 12),
              Flexible(child: Text(editing == null ? l10n.addCustomCity : l10n.editCustomCity)),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  onChanged: (_) => dialogSetState(() {}),
                  decoration: InputDecoration(
                    labelText: l10n.cityName,
                    prefixIcon: Icon(Icons.location_city_rounded),
                  ),
                ),
                TextField(
                  controller: countryController,
                  decoration: InputDecoration(
                    labelText: l10n.countryOptional,
                    prefixIcon: Icon(Icons.public_rounded),
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: selectedFlag,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.flagOptional,
                    prefixIcon: Icon(Icons.flag_rounded),
                  ),
                  items: countries.entries
                      .map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Row(
                              children: [
                                Image.asset('assets/flags/${entry.key}', width: 28),
                                const SizedBox(width: 8),
                                Text(entry.value),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (value) => dialogSetState(() => selectedFlag = value),
                ),
                DropdownButtonFormField<String>(
                  value: selectedTimeZone,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.ianaTimeZone,
                    prefixIcon: Icon(Icons.schedule_rounded),
                  ),
                  items: timeZones
                      .map((zone) => DropdownMenuItem(value: zone, child: Text(zone)))
                      .toList(),
                  onChanged: (value) => dialogSetState(() => selectedTimeZone = value),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.customCityOfflineHint,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: nameController.text.trim().isEmpty || selectedTimeZone == null
                  ? null
                  : () {
                      final template = _cities.firstWhere(
                        (item) => item.timeZone == selectedTimeZone,
                      );
                      Navigator.pop(
                        context,
                        City(
                          name: nameController.text.trim(),
                          country: countryController.text.trim(),
                          timeZone: selectedTimeZone!,
                          flag: selectedFlag ?? '',
                          utc: template.utc,
                          weatherZone: nameController.text.trim(),
                          latitude: template.latitude,
                          longitude: template.longitude,
                          isCustom: true,
                        ),
                      );
                    },
              child: Text(l10n.add),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    countryController.dispose();
    if (city == null) return;

    final prefs = await SharedPreferences.getInstance();
    final customCities = _cities.where((item) => item.isCustom && item != editing).toList()..add(city);
    await prefs.setString(
      'customCities',
      jsonEncode(customCities.map((item) => item.toJson()).toList()),
    );
    setState(() {
      if (editing != null) {
        final position = _cities.indexOf(editing);
        _cities[position] = city;
      } else {
        _cities.add(city);
      }
      _filteredCities = _orderedCities(_cities);
      _selectedOption = city;
    });
    await _saveSelectedCity('selectedOption', city);
  }

  Future<void> _deleteCustomCity(City city) async {
    final prefs = await SharedPreferences.getInstance();
    _cities.remove(city);
    await prefs.setString('customCities', jsonEncode(
      _cities.where((item) => item.isCustom).map((item) => item.toJson()).toList(),
    ));
    if (_selectedOption == city) {
      _selectedOption = _cities.first;
      await _saveSelectedCity('selectedOption', _selectedOption);
    }
    setState(() => _filteredCities = _orderedCities(_cities));
  }

  List<City> _orderedCities(Iterable<City> cities) {
    final result = cities.toList();
    result.sort((a, b) {
      if (a.isCustom != b.isCustom) return a.isCustom ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    return result;
  }

  void _searchCities(String query) {
    final filtered = _cities.where((city) {
      final cityName = city.name.toLowerCase();
      final cityCountry = city.country.toLowerCase();
      final cityTimeZone = city.timeZone.toLowerCase();
      final cityUtc = city.utc.toLowerCase();
      final searchQuery = query.toLowerCase();

      return cityName.contains(searchQuery) ||
          cityCountry.contains(searchQuery) ||
          cityTimeZone.contains(searchQuery) ||
          cityUtc.contains(searchQuery);
    }).toList();

    setState(() {
      _filteredCities = _orderedCities(filtered);
    });
  }

  void sortCities(sorting) {
    setState(() {
      switch (sorting) {
        case "sortByCity":
          _filteredCities = _orderedCities(_filteredCities);
          break;
        case "sortByCountry":
          _filteredCities.sort((a, b) {
            if (a.isCustom != b.isCustom) return a.isCustom ? -1 : 1;
            return a.country.compareTo(b.country);
          });
          break;
        case "sortByUtc":
          _filteredCities.sort((a, b) {
            if (a.isCustom != b.isCustom) return a.isCustom ? -1 : 1;
            return compareUtc(a.utc, b.utc);
          });
          break;
        case "sortByContinent":
          //_filteredCities.sort((a, b) => a.name.compareTo(b.name));
          _filteredCities.sort((a, b) {
            if (a.isCustom != b.isCustom) return a.isCustom ? -1 : 1;
            return a.timeZone.compareTo(b.timeZone);
          });
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
      _filteredCities = _orderedCities(cities);
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
    final l10n = AppLocalizations.of(context)!;
    int filteredCitiesCount = _filteredCities.length;
    return Consumer<SettingsProvider>(builder: (context, settings, child) {
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
              fontFamily: 'Red Hat Display',
              colorScheme: lightColorScheme,
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              fontFamily: 'Red Hat Display',
              colorScheme: darkColorScheme,
              useMaterial3: true,
            ),
            themeMode: themeModePreference,
            home: Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              appBar: AppBar(
                actions: [
                  PopupMenuButton<String>(
                    tooltip: "Sort the list",
                    onSelected: (sorting) {
                      HapticFeedback.lightImpact();
                      // Hier kannst du die entsprechende Sortierlogik basierend auf dem ausgewählten Wert implementieren
                      sortCities(sorting);
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'sortByCity',
                        child: ListTile(
                          leading: Icon(Icons.location_city_rounded, semanticLabel: l10n.sortByCity),
                          title: Text(
                            l10n.sortByCity,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'sortByCountry',
                        child: ListTile(
                          leading: Icon(Icons.flag_rounded, semanticLabel: l10n.sortByCountry),
                          title: Text(
                            l10n.sortByCountry,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'sortByUtc',
                        child: ListTile(
                          leading: Icon(Icons.access_time_filled, semanticLabel: l10n.sortByUtc),
                          title: Text(
                            l10n.sortByUtc,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'sortByContinent',
                        child: ListTile(
                          leading: Icon(Icons.public, semanticLabel: l10n.sortByContinent),
                          title: Text(
                            l10n.sortByContinent,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                    icon: Icon(Icons.sort, color: Theme.of(context).colorScheme.onPrimaryContainer, semanticLabel: "Sort"),
                  ),
                ],
                centerTitle: true,
                title: Text(l10n.chooseCity,
                    style: TextStyle(
                        fontFamily: "Pacifico",
                        fontSize: 24,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer)),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, semanticLabel: l10n.ok),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context, _selectedOption);
                  },
                ),
              ),
              body: _showMap
                  ? WorldMap(
                      cities: _cities,
                      selectedCity: _selectedOption,
                      onCityTap: (city) {
                        setState(() => _selectedOption = city);
                        _saveSelectedCity('selectedOption', city);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.citySelected(city.name))),
                        );
                      },
                    )
                  : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: TextField(
                      onChanged: (query) => _searchCities(query),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.searchHint(filteredCitiesCount),
                        prefixIcon: Icon(Icons.search, semanticLabel: l10n.searchCity),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredCities.length,
                      itemBuilder: (context, index) {
                        final city = _filteredCities[index];
                        return RadioListTile(
                          isThreeLine: true,
                          value: city,
                          groupValue: _selectedOption,
                          onChanged: (value) {
                            HapticFeedback.lightImpact();
                            setState(() {
                            _selectedOption = value!;
                              _saveSelectedCity('selectedOption', value);
                            });
                          },
                          title: Text(
                            city.name,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                              "${city.country.isEmpty ? '' : '${city.country}, '}UTC${city.utc} \n${city.timeZone}"),
                          secondary: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 40,
                                child: city.flag.isEmpty
                                    ? const Icon(Icons.star_rounded)
                                    : Image.asset("assets/flags/${city.flag}"),
                              ),
                              if (city.isCustom)
                                PopupMenuButton<String>(
                                  onSelected: (action) {
                                    if (action == 'edit') _addCustomCity(editing: city);
                                    if (action == 'delete') _deleteCustomCity(city);
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                                    PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                                  ],
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              floatingActionButton: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'addCustomCity',
                    tooltip: l10n.addCustomCity,
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    foregroundColor: Theme.of(context).colorScheme.onTertiary,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _addCustomCity();
                    },
                    child: const Icon(Icons.add_location_alt_rounded),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.small(
                    heroTag: 'toggleMap',
                    tooltip: _showMap ? 'Show list' : 'Show map',
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    onPressed: () => setState(() => _showMap = !_showMap),
                    child: Icon(_showMap ? Icons.list_rounded : Icons.map_rounded),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'confirmCity',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context, _selectedOption);
                    },
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    child: Icon(Icons.check, semanticLabel: l10n.ok),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
