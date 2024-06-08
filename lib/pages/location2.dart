import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'City Search',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CitySearchScreen(),
    );
  }
}

class City {
  final String name;
  final String country;
  final String timeZone;

  City({required this.name, required this.country, required this.timeZone});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'],
      country: json['country'],
      timeZone: json['timeZone'],
    );
  }
}

Future<List<City>> loadCities() async {
  final String response =
      await rootBundle.loadString('assets/data/cities.json');
  final data = await json.decode(response) as List;
  return data.map((city) => City.fromJson(city)).toList();
}

class CitySearchScreen extends StatefulWidget {
  const CitySearchScreen({super.key});

  @override
  _CitySearchScreenState createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends State<CitySearchScreen> {
  List<City> _cities = [];
  List<City> _filteredCities = [];

  @override
  void initState() {
    super.initState();
    loadCities().then((cities) {
      setState(() {
        _cities = cities;
        _filteredCities = cities;
      });
    });
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('City Search')),
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
                return ListTile(
                  title: Text(_filteredCities[index].name),
                  subtitle: Text(_filteredCities[index].country),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
