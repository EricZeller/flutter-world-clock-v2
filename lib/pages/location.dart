import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/main.dart';
import 'package:world_clock_v2/data/cities.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key, required this.title});

  final String title;

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  
  String? _selectedOption = "Berlin";

  Future<void> getSelectedOption() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedOption = prefs.getString('selectedOption');
      _selectedOption ??= 'Berlin';
    });
  }

  Future<void> _saveStringValue(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    print(key + value);
  }

  @override
  void initState() {
    super.initState();
    getSelectedOption();
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
        lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.blue).harmonized();
        darkColorScheme = ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark).harmonized();
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
        themeMode: ThemeMode.system,
        home: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(widget.title),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                //print(_selectedOption);
                Navigator.pop(context, _selectedOption);
              },
            ),
          ),
          body: ListView(
            children: cities.map((city) {
              return RadioListTile(
                value: city.name,
                groupValue: _selectedOption,
                onChanged: (String? value) {
                  setState(() {
                    _selectedOption = value!;
                    _saveStringValue('selectedOption', _selectedOption!);
                  });
                },
                tileColor: Theme.of(context).colorScheme.secondaryContainer,
                title: Text('${city.name}, ${city.country}', style: TextStyle(fontFamily: 'Red Hat Display', fontWeight: FontWeight.bold, fontSize: 20),),
                subtitle: Text(city.timeZone),
                secondary: ClipRRect(
                  child: Image.asset(
                    "assets/flags/${city.image}",
                    width: 40,
                  ),
                ),
              );
            }).toList(),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.pop(context, _selectedOption),
            child: Icon(Icons.check),
          ),
        ),
      );
    });
  }
}

class City {
  final String name;
  final String timeZone;
  final String image;
  final String weatherZone;
  final String country;

  City({required this.name, required this.timeZone, required this.image, required this.weatherZone, required this.country});
}
