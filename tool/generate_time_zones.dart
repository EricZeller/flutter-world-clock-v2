// Generates the time zone data of the app from package:timezone and the
// tz database's zone.tab:
//
// - assets/data/country_zones.json: the time zones of every country of
//   assets/data/cities.json, keyed by the ISO code of the country's flag
//   (`de` for `de.webp`), each as `[zone, latitude, longitude]` with the
//   zone.tab comment appended if there is one. The coordinates are those of
//   the zone's principal location. A zone.tab zone that is an alias of a
//   zone used by the country's cities is listed under the cities' name.
//   Countries without a zone.tab entry (Kosovo) are left out; the app falls
//   back to the zones of their cities.
// - assets/data/timezones.tzf: the time zone rules of all zones of
//   cities.json and of country_zones.json, limited to transitions from 2000
//   on. The full database of package:timezone adds about 450 KB to the app.
//
// tool/data/zone.tab is a copy of zone.tab from the tzdata release that
// package:timezone was built from (see [zoneTabVersion]). Run this after
// changing cities.json or upgrading package:timezone:
//
//   dart run tool/generate_time_zones.dart
//
// After upgrading package:timezone, first replace tool/data/zone.tab with
// the one of the matching release (the version is in the header of
// package:timezone's lib/data/latest_all.dart), e.g. for 2026e:
//
//   curl -O https://data.iana.org/time-zones/releases/tzdata2026e.tar.gz
//   tar -xzf tzdata2026e.tar.gz zone.tab && mv zone.tab tool/data/zone.tab
//
// and update [zoneTabVersion].
//
// ignore_for_file: implementation_imports, avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/src/tools.dart';
import 'package:timezone/src/tzdb.dart';
import 'package:timezone/timezone.dart' as tz;

/// The tzdata release of tool/data/zone.tab.
const zoneTabVersion = '2026e';

const citiesPath = 'assets/data/cities.json';
const zoneTabPath = 'tool/data/zone.tab';
const timeZonesPath = 'assets/data/timezones.tzf';
const countryZonesPath = 'assets/data/country_zones.json';

Future<void> main() async {
  await checkTimeZoneVersion();
  tz.initializeTimeZones();
  final database = tz.timeZoneDatabase;

  final cities = jsonDecode(File(citiesPath).readAsStringSync()) as List;
  final cityZones = {for (final city in cities) city['timeZone'] as String};
  final zonesByCountry = <String, Set<String>>{};
  for (final city in cities) {
    zonesByCountry
        .putIfAbsent(countryCode(city['flag'] as String), () => {})
        .add(city['timeZone'] as String);
  }

  final zoneTab = readZoneTab(File(zoneTabPath).readAsLinesSync());
  final missing = {
    ...cityZones,
    for (final zones in zoneTab.values)
      for (final zone in zones) zone.name,
  }.where((zone) => !database.locations.containsKey(zone));
  if (missing.isNotEmpty) {
    stderr.writeln('Unknown time zones: ${missing.join(', ')}');
    exit(1);
  }

  final countryZones = <String, List<ZoneTabEntry>>{};
  for (final MapEntry(key: code, value: ownZones)
      in (zonesByCountry.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key)))) {
    final zones = zoneTab[code];
    if (zones == null) {
      print(
        'No zone.tab entry for "$code", the app uses the zones of its '
        'cities: ${ownZones.join(', ')}',
      );
      continue;
    }
    countryZones[code] = [
      for (final zone in zones)
        zone.renamed(
          ownZones.firstWhere(
            (own) => sameRules(database, own, zone.name),
            orElse: () => zone.name,
          ),
        ),
    ];
  }

  final zones = {
    ...cityZones,
    for (final entries in countryZones.values)
      for (final entry in entries) entry.name,
  };
  final filtered = filterTimeZoneData(
    database,
    dateFrom: DateTime.utc(2000).millisecondsSinceEpoch,
    locations: zones.toList(),
  );
  final data = tzdbSerialize(filtered.db);
  File(timeZonesPath).writeAsBytesSync(data);
  print(
    'Wrote ${zones.length} zones (${data.length} bytes) to '
    '$timeZonesPath',
  );

  // One country per line keeps the diffs readable.
  final json = [
    for (final MapEntry(key: code, value: entries) in countryZones.entries)
      '${jsonEncode(code)}:${jsonEncode(entries)}',
  ].join(',\n');
  File(countryZonesPath).writeAsStringSync('{\n$json\n}\n');
  print(
    'Wrote the zones of ${countryZones.length} countries '
    '(${File(countryZonesPath).lengthSync()} bytes) to $countryZonesPath',
  );
}

/// Fails unless package:timezone was built from the tzdata release of
/// tool/data/zone.tab.
Future<void> checkTimeZoneVersion() async {
  final uri = await Isolate.resolvePackageUri(
    Uri.parse('package:timezone/data/latest_all.dart'),
  );
  final header = File.fromUri(uri!).readAsLinesSync().take(5).join('\n');
  final version = RegExp(
    r'Timezone data version: (\S+)',
  ).firstMatch(header)?.group(1);
  if (version != zoneTabVersion) {
    stderr.writeln(
      'package:timezone uses tzdata $version, but '
      '$zoneTabPath is from $zoneTabVersion. Replace it with the zone.tab '
      'of tzdata $version and update zoneTabVersion.',
    );
    exit(1);
  }
}

/// `de` for the flag `de.webp`.
String countryCode(String flag) => flag.split('.').first.toLowerCase();

/// Whether [a] and [b] are the same zone under two names, such as
/// `Europe/Kiev` and `Europe/Kyiv`.
bool sameRules(tz.LocationDatabase database, String a, String b) {
  if (a == b) return true;
  final first = database.locations[a]!;
  final second = database.locations[b]!;
  bool sameList<T>(List<T> x, List<T> y) =>
      x.length == y.length &&
      Iterable.generate(x.length).every((i) => x[i] == y[i]);
  return sameList(first.transitionAt, second.transitionAt) &&
      sameList(first.transitionZone, second.transitionZone) &&
      sameList(first.zones, second.zones);
}

class ZoneTabEntry {
  const ZoneTabEntry(this.name, this.latitude, this.longitude, this.comment);

  final String name;
  final double latitude;
  final double longitude;
  final String comment;

  ZoneTabEntry renamed(String name) =>
      ZoneTabEntry(name, latitude, longitude, comment);

  List<Object> toJson() => [
    name,
    latitude,
    longitude,
    if (comment.isNotEmpty) comment,
  ];
}

/// The zones of zone.tab by lowercase country code, in the file's order.
Map<String, List<ZoneTabEntry>> readZoneTab(List<String> lines) {
  final result = <String, List<ZoneTabEntry>>{};
  for (final line in lines) {
    if (line.startsWith('#') || line.trim().isEmpty) continue;
    final columns = line.split('\t');
    final coordinates = RegExp(r'^([+-]\d+)([+-]\d+)$').firstMatch(columns[1])!;
    result
        .putIfAbsent(columns[0].toLowerCase(), () => [])
        .add(
          ZoneTabEntry(
            columns[2],
            parseCoordinate(coordinates.group(1)!, degreeDigits: 2),
            parseCoordinate(coordinates.group(2)!, degreeDigits: 3),
            columns.length > 3 ? columns[3].trim() : '',
          ),
        );
  }
  return result;
}

/// Parses `+4916` or `-0913718` (ISO 6709 degrees, minutes and optional
/// seconds) into decimal degrees, rounded to 4 places (about 10 m).
double parseCoordinate(String value, {required int degreeDigits}) {
  final sign = value.startsWith('-') ? -1 : 1;
  final digits = value.substring(1);
  final degrees = int.parse(digits.substring(0, degreeDigits));
  final minutes = int.parse(digits.substring(degreeDigits, degreeDigits + 2));
  final seconds = digits.length > degreeDigits + 2
      ? int.parse(digits.substring(degreeDigits + 2))
      : 0;
  final decimal = degrees + minutes / 60 + seconds / 3600;
  return sign * (decimal * 10000).round() / 10000;
}
