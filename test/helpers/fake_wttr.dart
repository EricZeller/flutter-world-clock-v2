import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:world_clock_v2/services/weather_service.dart';

/// Trimmed real response of `wttr.in/Berlin?format=j1&lang=de` for 2026-10-03.
final wttrBerlinFixture =
    File('test/fixtures/wttr_berlin_de.json').readAsStringSync();

/// The Berlin fixture without the UV index and moon phase, like answers of
/// servers that do not send them.
String get wttrBerlinWithoutUvAndMoon {
  final json = jsonDecode(wttrBerlinFixture) as Map<String, dynamic>;
  (json['current_condition'] as List).first.remove('uvIndex');
  for (final day in json['weather'] as List) {
    day.remove('uvIndex');
    final astronomy = (day['astronomy'] as List).first;
    astronomy.remove('moon_phase');
    astronomy.remove('moon_illumination');
  }
  return jsonEncode(json);
}

/// In-memory stand-in for a wttr.in server.
class FakeWttr {
  FakeWttr({
    this.statusCode = 200,
    this.offline = false,
    this.clock,
    String? body,
  }) : body = body ?? wttrBerlinFixture;

  /// Time stamp for downloaded reports, e.g. to seed an outdated cache.
  final DateTime Function()? clock;

  int statusCode;
  bool offline;

  /// The JSON answer; the Berlin fixture by default.
  final String body;

  /// When set, requests wait for this completer before answering.
  Completer<void>? hold;
  final requests = <Uri>[];

  late final WeatherService service = WeatherService(
    clock: clock,
    client: MockClient((request) async {
      requests.add(request.url);
      await hold?.future;
      if (offline) throw http.ClientException('offline', request.url);
      if (statusCode != 200) {
        return http.Response('location not found', statusCode);
      }
      return http.Response.bytes(utf8.encode(body), 200);
    }),
  );
}
