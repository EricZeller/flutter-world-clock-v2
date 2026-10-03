// Generates assets/data/timezones.tzf: the time zone rules of all zones used
// in assets/data/cities.json, limited to transitions from 2000 on.
//
// The full database of package:timezone adds about 450 KB to the app, while
// the app only needs the zones of its cities. Run this after changing
// cities.json or upgrading package:timezone:
//
//   dart run tool/generate_time_zones.dart
//
// ignore_for_file: implementation_imports, avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/src/tools.dart';
import 'package:timezone/src/tzdb.dart';
import 'package:timezone/timezone.dart' as tz;

const outputPath = 'assets/data/timezones.tzf';

void main() {
  tz.initializeTimeZones();
  final cities =
      jsonDecode(File('assets/data/cities.json').readAsStringSync()) as List;
  final zones = {for (final city in cities) city['timeZone'] as String};

  final missing = zones.where(
      (zone) => !tz.timeZoneDatabase.locations.containsKey(zone));
  if (missing.isNotEmpty) {
    stderr.writeln('Unknown time zones: ${missing.join(', ')}');
    exit(1);
  }

  final filtered = filterTimeZoneData(
    tz.timeZoneDatabase,
    dateFrom: DateTime.utc(2000).millisecondsSinceEpoch,
    locations: zones.toList(),
  );
  final data = tzdbSerialize(filtered.db);
  File(outputPath).writeAsBytesSync(data);
  print('Wrote ${zones.length} zones (${data.length} bytes) to $outputPath');
}
