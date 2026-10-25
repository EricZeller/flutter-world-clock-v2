// Generates assets/data/cities.json, the cities bundled with the app, from
// GeoNames (https://www.geonames.org, CC BY 4.0). The list has
//
// - every city that is already in cities.json, found by its GeoNames `id`.
//   Its name, country and time zone are kept, so favorites and widget
//   cities saved with it still match the bundled version (see
//   CityRepository); its coordinates, offset and population are refreshed.
//   Delete an entry to drop a city that no longer qualifies; one that still
//   does needs [excludedIds].
// - the [maxPerCountry] most populous cities with at least [minPopulation]
//   inhabitants of each country,
// - the capital of every country that has a city in the list.
//
// Only countries with a flag in assets/flags are bundled. A country that
// lacks one gets it from flagcdn.com (the flags of flagpedia.net the other
// flags come from), converted with cwebp like the others.
//
// A new city is named by its preferred English name in GeoNames, else by
// its GeoNames name. Two cities of a country with the same name are told
// apart by their region: `Suzhou (Jiangsu)`. The names of the cities in
// the other languages of the app go to tool/data/city_names.json, the
// preferred one first, which tool/generate_place_names.dart shows and adds
// to the search.
//
// GeoNames assigns time zones by zone1970.tab, which groups countries
// (Hanoi is Asia/Bangkok there); the app offers the zones of zone.tab, by
// country. A new city keeps its GeoNames zone if its country has that zone,
// otherwise it gets the zone of its country that has shown the same time
// since 1981 (Asia/Ho_Chi_Minh for Hanoi), see generate_time_zones.dart.
//
// A capital is marked as such (`capital`), for the labels of the map and
// the names of countries that share a name (China (Beijing) and China
// (Hong Kong) for the mainland and Hong Kong).
//
// The weather of a bundled city is looked up by its coordinates, which
// tells the Hyderabads of India and Pakistan apart; custom cities keep
// using their name.
//
// Downloads cities500.zip, alternateNamesV2.zip (200 MB),
// admin1CodesASCII.txt and countryInfo.txt into a cache directory, the
// system's temporary directory by default, and reuses what is there. Run
// this, then the two other generators:
//
//   dart run tool/generate_cities.dart [cache directory]
//   dart run tool/generate_time_zones.dart
//   dart run tool/generate_place_names.dart
//
// Needs unzip and cwebp (brew install webp).
//
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:world_clock_v2/utils/search.dart';

import 'generate_time_zones.dart'
    show
        ZoneTabEntry,
        checkTimeZoneVersion,
        readZoneTab,
        showSameTime,
        zoneTabPath;

const citiesPath = 'assets/data/cities.json';
const cityNamesPath = 'tool/data/city_names.json';
const flagsDir = 'assets/flags';

/// Cities with this many inhabitants are bundled, ...
const minPopulation = 500000;

/// ... but only this many of a country, the most populous. GeoNames counts
/// the whole prefecture of a Chinese city, which gives China more than 300
/// cities over half a million.
const maxPerCountry = 50;

/// Cities this close to a bigger city of their country are left out:
/// boroughs that GeoNames lists as places of their own (Brooklyn, Kowloon)
/// and suburbs (Guarulhos next to São Paulo), which the clock of the big
/// city serves. Cities are considered by their rank first (see
/// [featureRank]), so a regional center keeps its name against a
/// neighborhood with the same population.
const suburbDistanceKm = 20.0;

/// Places of these kinds are bundled; GeoNames feature codes. Left out are
/// sections of cities (PPLX: Manhattan, the wards of Tokyo), abandoned and
/// historical places, localities, farms and the like.
const cityFeatureCodes = {
  'PPL',
  'PPLA',
  'PPLA2',
  'PPLA3',
  'PPLA4',
  'PPLA5',
  'PPLC',
  'PPLG',
  'PPLS',
};

/// City states, whose districts GeoNames counts as cities over half a
/// million (Kowloon); only their capital is bundled, if it is big enough.
const cityStates = {'hk', 'mo', 'sg'};

/// GeoNames ids of cities bundled although they are smaller than
/// [minPopulation]. A city of cities.json stays anyway; this is for the
/// first run after adding one here.
const includedIds = {
  2885679, // Konstanz, Germany
};

/// GeoNames ids of places that qualify by their GeoNames population but are
/// no cities of that size: towns and districts that got the population of
/// their district or of a city of the same name.
const excludedIds = {
  64021, // Borama, Somalia: a town of 100,000
  1004866, // Evaton, South Africa: a township of 150,000
  1176358, // Jalalpur Pirwala, Pakistan: a town of 50,000
  1180942, // Chunian, Pakistan: a town of 70,000
  1184370, // Arifwala, Pakistan: a town of 100,000
  1194041, // Mohammadpur, Bangladesh: a town, population of the district
  1258393, // Rasapūdipalem, India: a village, population of Visakhapatnam
  1723510, // Budta, Philippines: a village, population of the province
  6847550, // Kota Kuala Muda, Malaysia: a town, population of the district
};

/// The app's languages besides English, see generate_place_names.dart.
const languages = ['de', 'es', 'fr', 'pt'];

/// English names of countries that are not called by their GeoNames name
/// (Ivory Coast), or that are listed under another country's name: Macau
/// as China, like Hong Kong. Other countries already in cities.json keep
/// their names.
const countryNames = {'ci': 'Côte d\'Ivoire', 'mo': 'China'};

const geoNamesBase = 'https://download.geonames.org/export/dump';
const flagBase = 'https://flagcdn.com/w80';

Future<void> main(List<String> args) async {
  await checkTimeZoneVersion();
  tz.initializeTimeZones();
  final cache = Directory(
    args.isNotEmpty
        ? args.first
        : '${Directory.systemTemp.path}/world_clock_geonames',
  )..createSync(recursive: true);
  final client = HttpClient();
  try {
    await generate(client, cache, tz.timeZoneDatabase);
  } finally {
    client.close();
  }
}

Future<void> generate(
  HttpClient client,
  Directory cache,
  tz.LocationDatabase database,
) async {
  final existing = [
    for (final city in jsonDecode(File(citiesPath).readAsStringSync()) as List)
      city as Map<String, dynamic>,
  ];
  for (final city in existing) {
    if (city['id'] is! int) {
      stderr.writeln('${city['name']} has no GeoNames id in $citiesPath');
      exit(1);
    }
  }
  final existingById = {for (final city in existing) city['id'] as int: city};

  final places = await readPlaces(client, cache);
  final byCountry = <String, List<Place>>{};
  for (final place in places.values) {
    byCountry.putIfAbsent(place.country, () => []).add(place);
  }
  for (final cities in byCountry.values) {
    cities.sort((a, b) => b.population.compareTo(a.population));
  }
  final countryInfo = await readCountryInfo(client, cache);

  // The cities to bundle, by GeoNames id: first those of cities.json, ...
  final wanted = <int, Place>{};
  for (final id in existingById.keys) {
    final place = places[id];
    if (place == null) {
      stderr.writeln(
        '${existingById[id]!['name']} ($id) is no populated place of '
        'GeoNames any more',
      );
      exit(1);
    }
    wanted[id] = place;
  }
  // ... then [includedIds], the big cities of each country and the capital
  // of each country that has a city, see the file comment.
  for (final id in includedIds) {
    final place = places[id];
    if (place == null) {
      stderr.writeln('$id of includedIds is no populated place of GeoNames');
      exit(1);
    }
    wanted[id] = place;
  }
  var skipped = 0;
  for (final MapEntry(key: country, value: places) in byCountry.entries) {
    final kept = [
      for (final place in places)
        if (wanted.containsKey(place.id)) place,
    ];
    final capital = capitalOf(places, countryInfo[country]);
    final chosen = <Place>[];
    {
      final candidates =
          places
              .where(
                (place) =>
                    place.population >= minPopulation &&
                    cityFeatureCodes.contains(place.featureCode) &&
                    !excludedIds.contains(place.id) &&
                    !wanted.containsKey(place.id) &&
                    (!cityStates.contains(country) || place == capital),
              )
              .toList()
            ..sort((a, b) {
              final byRank = featureRank(a).compareTo(featureRank(b));
              return byRank != 0
                  ? byRank
                  : b.population.compareTo(a.population);
            });
      for (final place in candidates) {
        final near = [...kept, ?capital, ...chosen].where(
          // A bigger city, or one as big: a small capital (New Delhi) does
          // not stand in for the metropolis next to it (Delhi).
          (other) =>
              other.id != place.id &&
              other.population >= place.population &&
              distanceKm(place, other) < suburbDistanceKm,
        );
        if (near.isNotEmpty) {
          skipped++;
          print(
            'Skipped ${place.name} (${country.toUpperCase()}), '
            '${distanceKm(place, near.first).round()} km from '
            '${near.first.name}',
          );
        } else {
          chosen.add(place);
        }
      }
      chosen.sort((a, b) => b.population.compareTo(a.population));
    }
    // A country without a city of its own is not bundled, nor its capital.
    if (kept.isEmpty && chosen.isEmpty) continue;
    // The cities of cities.json that are big enough count against the
    // limit, so running this again adds nothing.
    final bigKept = kept
        .where((place) => place.population >= minPopulation)
        .length;
    kept.addAll(chosen.take(max(0, maxPerCountry - bigKept)));
    if (capital == null) {
      print('Note: no capital of ${country.toUpperCase()} in GeoNames');
    } else if (!wanted.containsKey(capital.id) && !kept.contains(capital)) {
      kept.add(capital);
    }
    for (final place in kept) {
      wanted[place.id] = place;
    }
  }
  print('Skipped $skipped suburbs and boroughs');
  final countries = {for (final place in wanted.values) place.country};

  // Country names: those of cities.json, else GeoNames'.
  final countryName = <String, String>{};
  for (final city in existing) {
    final code = countryCode(city['flag'] as String);
    final name = countryNames[code] ?? city['country'] as String;
    if (countryName.putIfAbsent(code, () => name) != name) {
      stderr.writeln('$code is both ${countryName[code]} and $name');
      exit(1);
    }
  }
  for (final code in countries) {
    if (countryName.containsKey(code)) continue;
    final name = countryNames[code] ?? countryInfo[code]?.name;
    if (name == null) {
      stderr.writeln('GeoNames has no country ${code.toUpperCase()}');
      exit(1);
    }
    countryName[code] = name;
    print('New country: $name (${code.toUpperCase()})');
  }
  for (final code in countries) {
    await ensureFlag(client, cache, code);
  }

  final zoneTab = readZoneTab(File(zoneTabPath).readAsLinesSync());
  // The zones of the cities of cities.json by country, so new cities join
  // them (Europe/Kiev, which Kyiv uses, rather than its alias Europe/Kyiv).
  final existingZones = <String, List<String>>{};
  for (final city in existing) {
    final zones = existingZones.putIfAbsent(
      countryCode(city['flag'] as String),
      () => [],
    );
    if (!zones.contains(city['timeZone'])) {
      zones.add(city['timeZone'] as String);
    }
  }
  for (final zones in existingZones.values) {
    zones.sort();
  }
  final admin1 = await readAdmin1(client, cache);
  final names = await readAlternateNames(client, cache, wanted.keys.toSet());

  final cities = <Map<String, dynamic>>[];
  final cityNames = <int, Map<String, List<String>>>{};
  for (final place in wanted.values) {
    final known = existingById[place.id];
    final name = known?['name'] as String? ?? englishName(place, names);
    final timeZone =
        known?['timeZone'] as String? ??
        countryZone(
          database,
          zoneTab,
          existingZones[place.country] ?? const [],
          place,
          name,
        );
    cities.add({
      'id': place.id,
      'name': name,
      'country': countryName[place.country],
      'timeZone': timeZone,
      'utc': julyOffset(database, timeZone),
      'flag': '${place.country}.webp',
      'weatherZone': coordinates(place),
      'latitude': round(place.latitude),
      'longitude': round(place.longitude),
      'population': place.population,
      if (place.isCapital) 'capital': true,
    });
    // The preferred names first: the first one is the name shown.
    final translations = <String, List<String>>{};
    for (final language in languages) {
      final current = [
        for (final alt in names[place.id] ?? const <AlternateName>[])
          if (alt.language == language && alt.isCurrent) alt,
      ];
      final found = {
        for (final preferred in [true, false])
          ...([
            for (final alt in current)
              if (alt.isPreferred == preferred) alt.name,
          ]..sort()),
      };
      if (found.isNotEmpty) translations[language] = found.toList();
    }
    if (translations.isNotEmpty) cityNames[place.id] = translations;
  }
  disambiguate(cities, wanted, admin1, existingById);
  cities.sort((a, b) {
    final byCountry = compareNames(
      a['country'] as String,
      b['country'] as String,
    );
    return byCountry != 0
        ? byCountry
        : compareNames(a['name'] as String, b['name'] as String);
  });

  // One city per line keeps the diffs readable.
  File(
    citiesPath,
  ).writeAsStringSync('[\n${cities.map(jsonEncode).join(',\n')}\n]\n');
  print(
    'Wrote ${cities.length} cities of ${countries.length} countries '
    '(${File(citiesPath).lengthSync()} bytes) to $citiesPath, '
    '${cities.length - existing.length} new',
  );

  // One city per line keeps the diffs readable. Only the cities that stayed
  // after disambiguate.
  final kept = {for (final city in cities) city['id'] as int};
  final ids = cityNames.keys.where(kept.contains).toList()..sort();
  File(cityNamesPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '{\n${[for (final id in ids) '"$id":${jsonEncode(cityNames[id])}'].join(',\n')}\n}\n',
    );
  print(
    'Wrote the names of ${ids.length} cities in ${languages.join(', ')} '
    '(${File(cityNamesPath).lengthSync()} bytes) to $cityNamesPath',
  );
}

/// A populated place of GeoNames.
class Place {
  Place({
    required this.id,
    required this.name,
    required this.asciiName,
    required this.featureCode,
    required this.country,
    required this.admin1,
    required this.population,
    required this.timeZone,
    required this.latitude,
    required this.longitude,
  });

  /// Parses a line of cities500.txt; `null` for a place that is no city
  /// (feature class P).
  static Place? parse(String line) {
    final columns = line.split('\t');
    if (columns.length < 18 || columns[6] != 'P') return null;
    return Place(
      id: int.parse(columns[0]),
      name: columns[1],
      asciiName: columns[2],
      featureCode: columns[7],
      country: columns[8].toLowerCase(),
      admin1: columns[10],
      population: int.tryParse(columns[14]) ?? 0,
      timeZone: columns[17],
      latitude: double.parse(columns[4]),
      longitude: double.parse(columns[5]),
    );
  }

  final int id;
  final String name;

  /// The name in ASCII letters: Koeln for Köln.
  final String asciiName;

  /// `PPLC` for a capital.
  final String featureCode;

  /// Lowercase ISO code, like the flags.
  final String country;

  /// The region code, such as `04` for Jiangsu, see admin1CodesASCII.txt.
  final String admin1;
  final int population;
  final String timeZone;
  final double latitude;
  final double longitude;

  bool get isCapital => featureCode == 'PPLC';
}

class AlternateName {
  AlternateName(
    this.language,
    this.name, {
    required this.isPreferred,
    required this.isCurrent,
  });

  final String language;
  final String name;
  final bool isPreferred;

  /// Neither historic (Edo for Tokyo) nor colloquial.
  final bool isCurrent;
}

class CountryInfo {
  CountryInfo(this.name, this.capital);

  final String name;
  final String capital;
}

/// `de` for the flag `de.webp`.
String countryCode(String flag) => flag.split('.').first.toLowerCase();

/// The populated places of cities500.txt by GeoNames id.
Future<Map<int, Place>> readPlaces(HttpClient client, Directory cache) async {
  final zip = await download(client, cache, 'cities500.zip');
  final result = await Process.run('unzip', [
    '-p',
    zip.path,
    'cities500.txt',
  ], stdoutEncoding: utf8);
  if (result.exitCode != 0) {
    stderr.writeln('unzip ${zip.path}: ${result.stderr}');
    exit(1);
  }
  final places = <int, Place>{};
  for (final line in const LineSplitter().convert(result.stdout as String)) {
    final place = Place.parse(line);
    if (place != null) places[place.id] = place;
  }
  print('Read ${places.length} populated places of GeoNames');
  return places;
}

Future<Map<String, CountryInfo>> readCountryInfo(
  HttpClient client,
  Directory cache,
) async {
  final file = await download(client, cache, 'countryInfo.txt');
  return {
    for (final line in file.readAsLinesSync())
      if (!line.startsWith('#'))
        if (line.split('\t') case final columns when columns.length > 5)
          columns[0].toLowerCase(): CountryInfo(columns[4], columns[5]),
  };
}

/// Region names by code, such as `CN.04` to Jiangsu.
Future<Map<String, String>> readAdmin1(
  HttpClient client,
  Directory cache,
) async {
  final file = await download(client, cache, 'admin1CodesASCII.txt');
  return {
    for (final line in file.readAsLinesSync())
      if (line.split('\t') case final columns when columns.length > 1)
        columns[0]: columns[1],
  };
}

/// The names of the places [ids] in English and the app's languages.
/// alternateNamesV2.txt has 800 MB, so it is streamed out of the archive.
Future<Map<int, List<AlternateName>>> readAlternateNames(
  HttpClient client,
  Directory cache,
  Set<int> ids,
) async {
  final zip = await download(client, cache, 'alternateNamesV2.zip');
  final process = await Process.start('unzip', [
    '-p',
    zip.path,
    'alternateNamesV2.txt',
  ]);
  final wanted = {'en', ...languages};
  final result = <int, List<AlternateName>>{};
  final errors = process.stderr.transform(utf8.decoder).join();
  await for (final line
      in process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
    final columns = line.split('\t');
    if (columns.length < 8 || !wanted.contains(columns[2])) continue;
    final id = int.tryParse(columns[1]);
    if (id == null || !ids.contains(id)) continue;
    result
        .putIfAbsent(id, () => [])
        .add(
          AlternateName(
            columns[2],
            columns[3].trim(),
            isPreferred: columns[4] == '1',
            isCurrent: columns[6] != '1' && columns[7] != '1',
          ),
        );
  }
  if (await process.exitCode != 0) {
    stderr.writeln('unzip ${zip.path}: ${await errors}');
    exit(1);
  }
  print('Read the names of ${result.length} cities');
  return result;
}

/// The capital of a country: the capital of countryInfo.txt among its
/// places, else its most populous place marked as capital.
Place? capitalOf(List<Place> places, CountryInfo? info) {
  final capitals = places.where((place) => place.isCapital).toList();
  if (info != null) {
    final named = capitals.where(
      (place) => foldForSearch(place.name) == foldForSearch(info.capital),
    );
    if (named.isNotEmpty) return named.first;
  }
  return capitals.firstOrNull;
}

/// The English name of a new city: its preferred English name in GeoNames
/// (Cologne for Köln), else the GeoNames name. The GeoNames name wins over
/// a preferred name that only differs in diacritics (Hyderabad, not
/// Hyderābād) and among several preferred names (Dubai, not Dubai City).
/// Without a preferred name, an English name that is the ASCII spelling
/// wins (Herat for Herāt), as does the ASCII spelling of a name with marks
/// of transliteration (Kazan for Kazan’, Hodeidah stays Al Hudaydah) but
/// not of a name with the usual accents (São Paulo, Düsseldorf, İzmir).
String englishName(Place place, Map<int, List<AlternateName>> names) {
  final english = [
    for (final alt in names[place.id] ?? const <AlternateName>[])
      if (alt.language == 'en' && alt.isCurrent) alt,
  ];
  final preferred = [
    for (final alt in english)
      if (alt.isPreferred) alt.name,
  ];
  final folded = foldForSearch(place.name);
  String name;
  if (preferred.contains(place.name) ||
      preferred.any((name) => foldForSearch(name) == folded)) {
    name = place.name;
  } else if (preferred.isNotEmpty) {
    name = preferred.first;
  } else if (english.any((alt) => alt.name == place.asciiName)) {
    name = place.asciiName;
  } else {
    name = place.name;
  }
  if (hasTransliterationMarks(name)) {
    // Rājkot: an English name of GeoNames without the marks, else the
    // ASCII spelling.
    name =
        english
            .map((alt) => alt.name)
            .where(
              (other) =>
                  !hasTransliterationMarks(other) &&
                  foldForSearch(other) == foldForSearch(name),
            )
            .firstOrNull ??
        (name == place.name ? place.asciiName : foldMarks(name));
  }
  return name.replaceAll('’', '\'').replaceAll(RegExp(r"'$"), '');
}

/// [name] without macrons: Rajkot for Rājkot.
String foldMarks(String name) {
  const marks = {
    'ā': 'a',
    'ē': 'e',
    'ī': 'i',
    'ō': 'o',
    'ū': 'u',
    'Ā': 'A',
    'Ē': 'E',
    'Ī': 'I',
    'Ō': 'O',
    'Ū': 'U',
  };
  return name.split('').map((letter) => marks[letter] ?? letter).join();
}

/// Whether [name] has letters of a transliteration rather than of a
/// language written in Latin letters: macrons (Herāt), letters with dots or
/// hooks (Al Ḩudaydah, Huế) or apostrophes for soft signs (Kazan’).
bool hasTransliterationMarks(String name) => name.runes.any(
  (rune) =>
      const {
        0x101,
        0x113,
        0x12B,
        0x14D,
        0x16B,
        0x100,
        0x112,
        0x12A,
        0x14C,
        0x16A,
        0x2019,
        0x2018,
      }.contains(rune) ||
      (rune >= 0x1E00 && rune <= 0x1EFF),
);

/// Distance between two places in kilometers (haversine).
double distanceKm(Place a, Place b) {
  const radius = 6371.0;
  double rad(double degrees) => degrees * pi / 180;
  final dLat = rad(b.latitude - a.latitude);
  final dLon = rad(b.longitude - a.longitude);
  final h =
      pow(sin(dLat / 2), 2) +
      cos(rad(a.latitude)) * cos(rad(b.latitude)) * pow(sin(dLon / 2), 2);
  return 2 * radius * asin(sqrt(h));
}

/// The time zone of a new city: the first zone of its country that has
/// shown the same time as its GeoNames zone since 1981, among the zones of
/// the country's cities of cities.json ([cityZones]) first, then those of
/// zone.tab in their order. So Detroit gets America/New_York, as the app
/// folds America/Detroit into it (see generate_time_zones.dart), Hanoi
/// Asia/Ho_Chi_Minh instead of Asia/Bangkok, and Kharkiv Europe/Kiev, the
/// name Kyiv uses, instead of Europe/Kyiv. A zone that is like none of them
/// stays, with a warning.
String countryZone(
  tz.LocationDatabase database,
  Map<String, List<ZoneTabEntry>> zoneTab,
  List<String> cityZones,
  Place place,
  String name,
) {
  if (!database.locations.containsKey(place.timeZone)) {
    stderr.writeln('$name: unknown time zone ${place.timeZone}');
    exit(1);
  }
  final zones = {
    ...cityZones,
    for (final entry in zoneTab[place.country] ?? const <ZoneTabEntry>[])
      entry.name,
  }.where(database.locations.containsKey);
  for (final zone in zones) {
    if (zone == place.timeZone) return zone;
    if (showSameTime(database, zone, place.timeZone)) {
      print('Note: $name: ${place.timeZone} -> $zone');
      return zone;
    }
  }
  if (zones.isNotEmpty) {
    print(
      'Warning: $name keeps ${place.timeZone}, which is like no zone of '
      '${place.country.toUpperCase()} (${zones.join(', ')})',
    );
  }
  return place.timeZone;
}

/// The UTC offset of [timeZone] on 1 July of this year, as the app lists
/// it: `+02:00`.
String julyOffset(tz.LocationDatabase database, String timeZone) {
  final july = DateTime.utc(DateTime.now().year, 7);
  final offset = tz.TZDateTime.from(
    july,
    database.get(timeZone),
  ).timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final minutes = offset.inMinutes.abs();
  String two(int n) => n.toString().padLeft(2, '0');
  return '$sign${two(minutes ~/ 60)}:${two(minutes % 60)}';
}

/// Coordinates rounded to 2 places, about a kilometer.
double round(double coordinate) => (coordinate * 100).round() / 100;

/// `52.52,13.40`, the location wttr.in is asked for the weather: the
/// coordinates as they are listed.
String coordinates(Place place) =>
    '${round(place.latitude).toStringAsFixed(2)},'
    '${round(place.longitude).toStringAsFixed(2)}';

/// Renames new cities that share their name with another city of their
/// country after their region. Cities of cities.json keep their names.
void disambiguate(
  List<Map<String, dynamic>> cities,
  Map<int, Place> places,
  Map<String, String> admin1,
  Map<int, Map<String, dynamic>> existing,
) {
  final byName = <String, List<Map<String, dynamic>>>{};
  for (final city in cities) {
    byName
        .putIfAbsent('${city['country']}|${city['name']}', () => [])
        .add(city);
  }
  // GeoNames lists some cities twice (Sahiwal), or gives a town the
  // population of the city of the same name. Of records with the same name
  // within half a degree of each other, or with the same population, only
  // the most populous stays, the administrative center among equals, unless
  // both are in cities.json already.
  for (final same in byName.values.where((cities) => cities.length > 1)) {
    same.sort((a, b) {
      final byPopulation = (b['population'] as int).compareTo(
        a['population'] as int,
      );
      if (byPopulation != 0) return byPopulation;
      return featureRank(
        places[a['id'] as int]!,
      ).compareTo(featureRank(places[b['id'] as int]!));
    });
    for (var i = 1; i < same.length; i++) {
      final smaller = same[i];
      final twin = same
          .take(i)
          .where(
            (city) =>
                !(existing.containsKey(city['id']) &&
                    existing.containsKey(smaller['id'])) &&
                (city['population'] == smaller['population'] ||
                    ((city['latitude'] as double) -
                                    (smaller['latitude'] as double))
                                .abs() <
                            0.5 &&
                        ((city['longitude'] as double) -
                                    (smaller['longitude'] as double))
                                .abs() <
                            0.5),
          );
      if (twin.isEmpty) continue;
      print(
        'Dropped ${smaller['name']} (${smaller['id']}), listed twice in '
        'GeoNames',
      );
      cities.remove(smaller);
      same.removeAt(i--);
    }
  }
  for (final same in byName.values.where((cities) => cities.length > 1)) {
    for (final city in same) {
      final id = city['id'] as int;
      if (existing.containsKey(id)) continue;
      final place = places[id]!;
      final region = admin1['${place.country.toUpperCase()}.${place.admin1}'];
      if (region == null) {
        stderr.writeln('${city['name']}: no region to tell it apart by');
        exit(1);
      }
      city['name'] = '${city['name']} ($region)';
      print(
        'Renamed ${place.name} (${place.country.toUpperCase()}) to '
        '${city['name']}',
      );
    }
  }
  final names = <String>{};
  for (final city in cities) {
    if (!names.add('${city['country']}|${city['name']}|${city['timeZone']}')) {
      stderr.writeln('${city['name']}, ${city['country']} is listed twice');
      exit(1);
    }
  }
}

/// Capitals first, then regional centers of ever lower level, then towns.
int featureRank(Place place) => switch (place.featureCode) {
  'PPLC' => 0,
  'PPLA' => 1,
  'PPLA2' => 2,
  'PPLA3' => 3,
  'PPLA4' => 4,
  'PPL' => 6,
  _ => 5,
};

/// Fetches the flag of [code] if assets/flags lacks it.
Future<void> ensureFlag(HttpClient client, Directory cache, String code) async {
  final flag = File('$flagsDir/$code.webp');
  if (flag.existsSync()) return;
  final png = await download(
    client,
    cache,
    '$code.png',
    url: '$flagBase/$code.png',
  );
  final result = await Process.run('cwebp', [
    '-quiet',
    '-lossless',
    '-z',
    '9',
    '-exact',
    png.path,
    '-o',
    flag.path,
  ]);
  if (result.exitCode != 0) {
    stderr.writeln('cwebp ${png.path}: ${result.stderr}');
    exit(1);
  }
  print('Added the flag $flagsDir/$code.webp (${flag.lengthSync()} bytes)');
}

/// The file [name] of the cache, downloaded from [url] (by default the
/// GeoNames dump of that name) if it is not there yet.
Future<File> download(
  HttpClient client,
  Directory cache,
  String name, {
  String? url,
}) async {
  final file = File('${cache.path}/$name');
  if (file.existsSync()) return file;
  url ??= '$geoNamesBase/$name';
  print('Downloading $url');
  final request = await client.getUrl(Uri.parse(url));
  final response = await request.close();
  if (response.statusCode != HttpStatus.ok) {
    stderr.writeln('$url: HTTP ${response.statusCode}');
    exit(1);
  }
  final partial = File('${file.path}.part');
  await response.pipe(partial.openWrite());
  partial.renameSync(file.path);
  return file;
}
