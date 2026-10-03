import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:world_clock_v2/services/weather_service.dart';

/// Trimmed real response of `wttr.in/Berlin?format=j1&lang=de` for 2026-10-03.
final wttrBerlinFixture =
    File('test/fixtures/wttr_berlin_de.json').readAsStringSync();

/// In-memory stand-in for a wttr.in server.
class FakeWttr {
  FakeWttr({this.statusCode = 200, this.offline = false});

  int statusCode;
  bool offline;

  /// When set, requests wait for this completer before answering.
  Completer<void>? hold;
  final requests = <Uri>[];

  late final WeatherService service = WeatherService(
    client: MockClient((request) async {
      requests.add(request.url);
      await hold?.future;
      if (offline) throw http.ClientException('offline', request.url);
      if (statusCode != 200) {
        return http.Response('location not found', statusCode);
      }
      return http.Response.bytes(utf8.encode(wttrBerlinFixture), 200);
    }),
  );
}
