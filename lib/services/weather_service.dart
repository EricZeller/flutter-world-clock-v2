import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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
  /// Reports kept in the cache, one per server, place and language. Enough
  /// for many favorites and widget cities, so swiping through them does not
  /// evict reports needed offline; a report takes about 3 KB.
  static const maxCachedLocations = 50;

  /// How long a report counts as current.
  static const refreshInterval = Duration(minutes: 15);
  static const _timeout = Duration(seconds: 15);

  final http.Client _client;
  final DateTime Function() _clock;
  // Requests that are running, so callers asking for the same place share one.
  final _inFlight = <String, Future<WeatherResult>>{};

  static Uri buildUri(String server, String zone, {String? lang}) {
    return Uri.parse(
      '$server/${Uri.encodeComponent(zone)}',
    ).replace(queryParameters: {'format': 'j1', 'lang': ?lang});
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
        WeatherFailure.server,
        'HTTP ${response.statusCode}',
      );
    }
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return WeatherReport.fromWttr(json, fetchedAt: _clock(), lang: lang);
    } catch (e) {
      throw WeatherException(WeatherFailure.server, 'invalid data: $e');
    }
  }

  /// Fetches a fresh report and caches it; falls back to the cached report.
  /// Concurrent calls for the same request share one download. Never throws.
  Future<WeatherResult> refresh({
    required String server,
    required String zone,
    String? lang,
  }) {
    final key = cacheKeyFor(server: server, zone: zone, lang: lang);
    return _inFlight[key] ??= _refresh(server: server, zone: zone, lang: lang)
        // A block, not `=>`: returning the removed future would make
        // whenComplete wait for itself.
        .whenComplete(() {
          _inFlight.remove(key);
        });
  }

  /// The cached report while it is younger than [refreshInterval], otherwise
  /// a [refresh]. Never throws.
  Future<WeatherResult> current({
    required String server,
    required String zone,
    String? lang,
  }) async {
    final cached = await loadCached(server: server, zone: zone, lang: lang);
    if (cached != null &&
        _clock().difference(cached.fetchedAt) < refreshInterval) {
      return WeatherResult(report: cached);
    }
    return refresh(server: server, zone: zone, lang: lang);
  }

  Future<WeatherResult> _refresh({
    required String server,
    required String zone,
    String? lang,
  }) async {
    final WeatherReport report;
    try {
      report = await fetch(server: server, zone: zone, lang: lang);
    } on WeatherException catch (e) {
      // Offline, an older report in another language beats none at all.
      final cached = await loadCached(server: server, zone: zone, lang: lang) ??
          await _loadAnyCached(zone);
      return WeatherResult(report: cached, failure: e.failure);
    }
    try {
      await _store(cacheKeyFor(server: server, zone: zone, lang: lang), report);
    } catch (e) {
      // A failing cache must not hide the fresh report.
      debugPrint('Could not cache weather: $e');
    }
    return WeatherResult(report: report);
  }

  /// Reports are cached per server, place and language, so a changed
  /// server or app language never shows the old data as current.
  static String cacheKeyFor({
    required String server,
    required String zone,
    String? lang,
  }) =>
      '$server|$zone|${lang ?? 'en'}';

  /// The last cached report for this request, or `null` if none can be read.
  Future<WeatherReport?> loadCached({
    required String server,
    required String zone,
    String? lang,
  }) async {
    try {
      final entry = (await _loadCache())[
          cacheKeyFor(server: server, zone: zone, lang: lang)];
      return entry == null ? null : WeatherReport.fromJson(entry);
    } catch (_) {
      return null;
    }
  }

  /// The newest cached report of [zone] from any server or language.
  Future<WeatherReport?> _loadAnyCached(String zone) async {
    try {
      final cache = await _loadCache();
      final keys = cache.keys
          .where((key) => key.split('|').elementAtOrNull(1) == zone)
          .toList()
        ..sort((a, b) => _fetchedAt(cache[b]).compareTo(_fetchedAt(cache[a])));
      return keys.isEmpty ? null : WeatherReport.fromJson(cache[keys.first]);
    } catch (_) {
      return null;
    }
  }

  Future<void> _store(String key, WeatherReport report) async {
    final prefs = await SharedPreferences.getInstance();
    // Read and write without an await in between, so reports that finish
    // downloading at the same time do not drop each other from the cache.
    final cache = _readCache(prefs);
    cache[key] = report.toJson();
    // Keep only the most recently fetched locations.
    final zones = cache.keys.toList()
      ..sort((a, b) => _fetchedAt(cache[b]).compareTo(_fetchedAt(cache[a])));
    for (final stale in zones.skip(maxCachedLocations)) {
      cache.remove(stale);
    }
    await prefs.setString(cacheKey, jsonEncode(cache));
  }

  Future<Map<String, dynamic>> _loadCache() async =>
      _readCache(await SharedPreferences.getInstance());

  static Map<String, dynamic> _readCache(SharedPreferences prefs) {
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
