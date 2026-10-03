import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/models/weather.dart';

enum WeatherFailure {
  /// The server could not be reached, e.g. because the device is offline.
  network,

  /// The server answered with an error or unreadable data, e.g. for a city
  /// wttr.in does not know.
  server,
}

/// Outcome of a refresh: the newest available report (possibly from the
/// cache) and why fetching a fresh one failed, if it did.
class WeatherResult {
  const WeatherResult({this.report, this.failure});

  final WeatherReport? report;
  final WeatherFailure? failure;

  bool get isFresh => failure == null;
}

class WeatherException implements Exception {
  const WeatherException(this.failure, this.message);

  final WeatherFailure failure;
  final String message;

  @override
  String toString() => 'WeatherException($failure): $message';
}

/// Loads weather from a wttr.in server and caches the last report of each
/// location so it can be shown while offline.
class WeatherService {
  WeatherService({http.Client? client, DateTime Function()? clock})
      : _client = client ?? http.Client(),
        _clock = clock ?? DateTime.now;

  static const cacheKey = 'weatherCache';
  static const maxCachedLocations = 10;
  static const _timeout = Duration(seconds: 15);

  final http.Client _client;
  final DateTime Function() _clock;

  static Uri buildUri(String server, String zone, {String? lang}) {
    return Uri.parse('$server/${Uri.encodeComponent(zone)}').replace(
      queryParameters: {'format': 'j1', 'lang': ?lang},
    );
  }

  /// Fetches a fresh report, throwing a [WeatherException] on failure.
  Future<WeatherReport> fetch({
    required String server,
    required String zone,
    String? lang,
  }) async {
    final http.Response response;
    try {
      response = await _client
          .get(buildUri(server, zone, lang: lang))
          .timeout(_timeout);
    } on TimeoutException {
      throw const WeatherException(WeatherFailure.network, 'timeout');
    } catch (e) {
      throw WeatherException(WeatherFailure.network, '$e');
    }
    if (response.statusCode != 200) {
      throw WeatherException(
          WeatherFailure.server, 'HTTP ${response.statusCode}');
    }
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return WeatherReport.fromWttr(json, fetchedAt: _clock(), lang: lang);
    } catch (e) {
      throw WeatherException(WeatherFailure.server, 'invalid data: $e');
    }
  }

  /// Fetches a fresh report and caches it; falls back to the cached report.
  Future<WeatherResult> refresh({
    required String server,
    required String zone,
    String? lang,
  }) async {
    try {
      final report = await fetch(server: server, zone: zone, lang: lang);
      await _store(zone, report);
      return WeatherResult(report: report);
    } on WeatherException catch (e) {
      return WeatherResult(report: await loadCached(zone), failure: e.failure);
    }
  }

  Future<WeatherReport?> loadCached(String zone) async {
    final entry = (await _loadCache())[zone];
    if (entry == null) return null;
    try {
      return WeatherReport.fromJson(entry);
    } catch (_) {
      return null;
    }
  }

  Future<void> _store(String zone, WeatherReport report) async {
    final cache = await _loadCache();
    cache[zone] = report.toJson();
    // Keep only the most recently fetched locations.
    final zones = cache.keys.toList()
      ..sort((a, b) => _fetchedAt(cache[b]).compareTo(_fetchedAt(cache[a])));
    for (final stale in zones.skip(maxCachedLocations)) {
      cache.remove(stale);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cacheKey, jsonEncode(cache));
  }

  Future<Map<String, dynamic>> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(cacheKey);
    if (stored == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(stored));
    } catch (_) {
      return {};
    }
  }

  static String _fetchedAt(dynamic entry) =>
      entry is Map ? '${entry['fetchedAt'] ?? ''}' : '';

  void dispose() => _client.close();
}
