// Generates lib/data/place_names.g.dart, the names of the countries and
// cities of assets/data/cities.json in the languages of the app, from the
// Unicode CLDR (https://cldr.unicode.org), release [cldrVersion]:
//
// - countryNames: the name of each country by language and ISO code of its
//   flag (`de` for `de.webp`). English is the country of cities.json, so the
//   English app stays as it is. The other languages take the CLDR territory
//   name of the code, or of the CLDR key in [cldrKeys] where cities.json
//   uses another form of the name (`Congo (DRC)`) or another country's name
//   (Hong Kong as China).
// - cityExonyms: other names of the bundled cities by language and city
//   name, which the search finds them by (the cities keep the names of
//   cities.json). These are the CLDR exemplar cities of the time zones
//   whose exemplar city is the bundled city (Moskau for Europe/Moscow), and
//   [extraCityNames] for well-known cities that are no exemplar city.
//   Names that are found anyway are left out: Berlín, since the search
//   ignores diacritics, and Mexico, which is part of Mexico City.
//
// It also writes the countryNames of the other languages to
// macos/WorldClockWidget/CountryNames.swift, so the macOS widget shows the
// same names as the app (Foundation's own names differ, such as "China,
// Festland" for China).
//
// The app's Portuguese is that of Brazil, which is CLDR's `pt`.
//
// Downloads territories.json (cldr-localenames-full) and timeZoneNames.json
// (cldr-dates-full) of each language, about 330 KB in all, and the license
// from the cldr-json repository at the release tag; nothing is saved but
// the output. Run this after changing cities.json, or after updating
// [cldrVersion] to a newer release of
// https://github.com/unicode-org/cldr-json/releases:
//
//   dart run tool/generate_place_names.dart
//
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:world_clock_v2/utils/search.dart';

/// The release (tag) of https://github.com/unicode-org/cldr-json.
const cldrVersion = '48.2.3';

const citiesPath = 'assets/data/cities.json';
const outputPath = 'lib/data/place_names.g.dart';
const swiftOutputPath = 'macos/WorldClockWidget/CountryNames.swift';

/// The app's languages besides English.
const languages = ['de', 'es', 'fr', 'pt'];

/// CLDR territory keys for countries whose name in cities.json is not
/// CLDR's default English name of their code. Turkey keeps the default
/// Türkiye (TR): its variant is Türkiye in French. The Czech Republic keeps
/// the default Czechia (CZ), the usual name in the other languages
/// (Tschechien), which German users search for.
const cldrKeys = {
  'cd': 'CD-alt-variant', // Congo (DRC)
  'cg': 'CG-alt-variant', // Congo (Republic)
  'hk': 'CN', // China, like the rest of China
  'mm': 'MM-alt-short', // Myanmar
  'ps': 'PS-alt-short', // Palestine
};

/// Exceptions to [cldrKeys] by language: CLDR's Brazilian variant of the
/// Republic of the Congo is only "Congo".
const languageKeys = {
  'pt': {'cg': 'CG'},
};

/// Names of bundled cities that are no exemplar city of a CLDR time zone,
/// by language and the city's name in cities.json.
const extraCityNames = {
  'de': {
    'Beijing': ['Peking'],
    'Munich': ['München'],
    'New Delhi': ['Neu-Delhi'],
  },
  'es': {
    'Abu Dhabi': ['Abu Dabi'],
    'Beijing': ['Pekín'],
    'Bern': ['Berna'],
    'Munich': ['Múnich'],
    'New Delhi': ['Nueva Delhi'],
    'Valletta': ['La Valeta'],
  },
  'fr': {
    'Abu Dhabi': ['Abou Dabi'],
    'Barcelona': ['Barcelone'],
    'Beijing': ['Pékin'],
    'Bern': ['Berne'],
    'Valletta': ['La Valette'],
  },
  'pt': {
    'Beijing': ['Pequim'],
    'Bern': ['Berna'],
    'Munich': ['Munique'],
    'New Delhi': ['Nova Délhi'],
  },
};

const _base =
    'https://raw.githubusercontent.com/unicode-org/cldr-json/$cldrVersion';

Future<void> main() async {
  final client = HttpClient();
  try {
    await generate(client);
  } finally {
    client.close();
  }
}

Future<void> generate(HttpClient client) async {
  final cities = jsonDecode(File(citiesPath).readAsStringSync()) as List;
  final english = <String, String>{};
  for (final city in cities) {
    final code = countryCode(city['flag'] as String);
    final country = city['country'] as String;
    if (english.putIfAbsent(code, () => country) != country) {
      stderr.writeln('$code is both ${english[code]} and $country');
      exit(1);
    }
  }
  final codes = english.keys.toList()..sort();
  final names = {for (final city in cities) city['name'] as String};
  for (final name in [
    for (final byCity in extraCityNames.values) ...byCity.keys,
  ]) {
    if (!names.contains(name)) {
      stderr.writeln('$name of extraCityNames is no city of $citiesPath');
      exit(1);
    }
  }

  final englishTerritories = await territories(client, 'en');
  for (final code in codes) {
    final key = cldrKeys[code] ?? code.toUpperCase();
    final cldrName = englishTerritories[key];
    if (cldrName == null) {
      stderr.writeln('CLDR has no territory $key for $code');
      exit(1);
    }
    if (cldrName != english[code]) {
      // Typography (St. Kitts & Nevis) is fine; anything else may need an
      // entry in cldrKeys.
      print('Note: $code is ${english[code]} in $citiesPath, $cldrName in '
          'CLDR ($key)');
    }
  }

  final englishZones = await exemplarCities(client, 'en');
  final countryNames = <String, Map<String, String>>{
    'en': {for (final code in codes) code: english[code]!},
  };
  final cityExonyms = <String, Map<String, List<String>>>{};
  for (final language in languages) {
    final names = await territories(client, language);
    countryNames[language] = {
      for (final code in codes)
        code: names[languageKeys[language]?[code] ??
                cldrKeys[code] ??
                code.toUpperCase()] ??
            names[code.toUpperCase()]!,
    };

    final zones = await exemplarCities(client, language);
    final exonyms = <String, Set<String>>{};
    for (final city in cities) {
      final name = city['name'] as String;
      final zone = city['timeZone'] as String;
      final exemplar = englishZones[zone] ?? zoneCity(zone);
      if (foldForSearch(exemplar) != foldForSearch(name)) continue;
      final local = zones[zone];
      if (local != null) exonyms.putIfAbsent(name, () => {}).add(local);
    }
    for (final MapEntry(key: name, value: extra)
        in (extraCityNames[language] ?? const {}).entries) {
      exonyms.putIfAbsent(name, () => {}).addAll(extra);
    }
    cityExonyms[language] = {
      for (final name in exonyms.keys.toList()..sort())
        if (exonyms[name]!
                .where((exonym) =>
                    !foldForSearch(name).contains(foldForSearch(exonym)))
                .toList()
            case final found when found.isNotEmpty)
          name: found,
    };
  }

  final license = await download(client, '$_base/LICENSE');
  File(outputPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(dartSource(countryNames, cityExonyms, license));
  File(swiftOutputPath).writeAsStringSync(swiftSource(countryNames, license));
  print(
    'Wrote ${codes.length} countries and '
    '${cityExonyms.values.fold(0, (sum, cities) => sum + cities.length)} '
    'city names (${File(outputPath).lengthSync()} bytes) to $outputPath, '
    'and the countries to $swiftOutputPath',
  );
}

/// `de` for the flag `de.webp`.
String countryCode(String flag) => flag.split('.').first.toLowerCase();

/// `New York` for `America/New_York`, the English exemplar city of a zone
/// that CLDR does not list.
String zoneCity(String zone) => zone.split('/').last.replaceAll('_', ' ');

/// CLDR inserts soft hyphens into some long names (Reyk­ja­vík).
String clean(String name) => name.replaceAll('­', '').trim();

Future<String> download(HttpClient client, String url) async {
  final request = await client.getUrl(Uri.parse(url));
  final response = await request.close();
  if (response.statusCode != HttpStatus.ok) {
    stderr.writeln('$url: HTTP ${response.statusCode}');
    exit(1);
  }
  return response.transform(utf8.decoder).join();
}

/// The territory names of [language] by CLDR key, such as `DE` or
/// `CD-alt-variant`.
Future<Map<String, String>> territories(
  HttpClient client,
  String language,
) async {
  final json = jsonDecode(await download(
    client,
    '$_base/cldr-json/cldr-localenames-full/main/$language/territories.json',
  ));
  final names = json['main'][language]['localeDisplayNames']['territories']
      as Map<String, dynamic>;
  return names.map((key, name) => MapEntry(key, clean(name as String)));
}

/// The exemplar cities of [language] by IANA zone id.
Future<Map<String, String>> exemplarCities(
  HttpClient client,
  String language,
) async {
  final json = jsonDecode(await download(
    client,
    '$_base/cldr-json/cldr-dates-full/main/$language/timeZoneNames.json',
  ));
  final result = <String, String>{};
  void visit(Map<String, dynamic> node, String path) {
    for (final MapEntry(:key, :value) in node.entries) {
      if (key == 'exemplarCity' && value is String) {
        result[path] = clean(value);
      } else if (value is Map<String, dynamic>) {
        visit(value, path.isEmpty ? key : '$path/$key');
      }
    }
  }

  visit(
    json['main'][language]['dates']['timeZoneNames']['zone']
        as Map<String, dynamic>,
    '',
  );
  return result;
}

/// A Dart string literal of [text].
String literal(String text) {
  final escaped = text
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$');
  return "'$escaped'";
}

/// A Swift string literal of [text].
String swiftLiteral(String text) =>
    '"${text.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';

/// The comment that starts both outputs, with the CLDR [license].
String header(String license) {
  final out = StringBuffer()
    ..writeln('// GENERATED by tool/generate_place_names.dart from the '
        'Unicode CLDR')
    ..writeln('// $cldrVersion (https://cldr.unicode.org). Do not edit; run')
    ..writeln('// `dart run tool/generate_place_names.dart` instead.')
    ..writeln('//')
    ..writeln('// The CLDR data is distributed under the following license:')
    ..writeln('//');
  for (final line in const LineSplitter().convert(license.trim())) {
    out.writeln(line.isEmpty ? '//' : '// $line');
  }
  return out.toString();
}

String dartSource(
  Map<String, Map<String, String>> countryNames,
  Map<String, Map<String, List<String>>> cityExonyms,
  String license,
) {
  final out = StringBuffer(header(license))
    ..writeln()
    ..writeln('/// The CLDR release of the names.')
    ..writeln("const cldrVersion = '$cldrVersion';")
    ..writeln()
    ..writeln('/// The countries of the bundled cities by language and ISO '
        'code of their')
    ..writeln('/// flag. English is the name the cities are stored with.')
    ..writeln('const countryNames = <String, Map<String, String>>{');
  for (final MapEntry(key: language, value: names) in countryNames.entries) {
    out.writeln('  ${literal(language)}: {');
    for (final MapEntry(key: code, value: name) in names.entries) {
      out.writeln('    ${literal(code)}: ${literal(name)},');
    }
    out.writeln('  },');
  }
  out
    ..writeln('};')
    ..writeln()
    ..writeln('/// Other names of bundled cities by language and the name '
        'the city is')
    ..writeln('/// stored with, which the search finds the city by.')
    ..writeln('const cityExonyms = <String, Map<String, List<String>>>{');
  for (final MapEntry(key: language, value: cities) in cityExonyms.entries) {
    out.writeln('  ${literal(language)}: {');
    for (final MapEntry(key: city, value: names) in cities.entries) {
      out.writeln(
        '    ${literal(city)}: [${names.map(literal).join(', ')}],',
      );
    }
    out.writeln('  },');
  }
  out.writeln('};');
  return out.toString();
}

/// The countryNames of the languages besides English for the macOS widget,
/// which shows the English names of cities.json itself.
String swiftSource(
  Map<String, Map<String, String>> countryNames,
  String license,
) {
  final out = StringBuffer(header(license))
    ..writeln()
    ..writeln('/// The countries of the bundled cities by language and ISO '
        'code of their')
    ..writeln('/// flag, as the app shows them (lib/data/place_names.g.dart). '
        'English is')
    ..writeln('/// the country of cities.json.')
    ..writeln('enum CountryNames {')
    ..writeln('    static let byLanguage: [String: [String: String]] = [');
  for (final MapEntry(key: language, value: names) in countryNames.entries) {
    if (language == 'en') continue;
    out.writeln('        ${swiftLiteral(language)}: [');
    for (final MapEntry(key: code, value: name) in names.entries) {
      out.writeln('            ${swiftLiteral(code)}: ${swiftLiteral(name)},');
    }
    out.writeln('        ],');
  }
  out
    ..writeln('    ]')
    ..writeln('}');
  return out.toString();
}
