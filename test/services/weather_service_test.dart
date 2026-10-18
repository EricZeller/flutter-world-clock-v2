import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/services/weather_service.dart';

import '../helpers/fake_wttr.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const server = 'https://wttr.in';

  group('buildUri', () {
    test('encodes the location and adds the language', () {
      expect(
        WeatherService.buildUri(server, 'São Paulo', lang: 'pt').toString(),
        'https://wttr.in/S%C3%A3o%20Paulo?format=j1&lang=pt',
      );
      expect(
        WeatherService.buildUri(
          'https://example.org',
          'Washington, D.C.',
        ).toString(),
        'https://example.org/Washington%2C%20D.C.?format=j1',
      );
    });
  });

  group('refresh', () {
    test('returns a fresh report and caches it', () async {
      final wttr = FakeWttr();

      final result = await wttr.service.refresh(
        server: server,
        zone: 'Berlin',
        lang: 'de',
      );

      expect(result.isFresh, isTrue);
      expect(result.failure, isNull);
      expect(result.report!.current.description, 'Wolkig');
      expect(wttr.requests.single.queryParameters, {
        'format': 'j1',
        'lang': 'de',
      });
      final cached = await wttr.service.loadCached(
        server: server,
        zone: 'Berlin',
        lang: 'de',
      );
      expect(cached!.toJson(), result.report!.toJson());
    });

    test('falls back to the cache when offline', () async {
      final wttr = FakeWttr();
      final fresh = await wttr.service.refresh(server: server, zone: 'Berlin');
      wttr.offline = true;

      final result = await wttr.service.refresh(server: server, zone: 'Berlin');

      expect(result.failure, WeatherFailure.network);
      expect(result.isFresh, isFalse);
      expect(result.report!.toJson(), fresh.report!.toJson());
    });

    test('reports a network failure without cache', () async {
      final wttr = FakeWttr(offline: true);

      final result = await wttr.service.refresh(server: server, zone: 'Berlin');

      expect(result.failure, WeatherFailure.network);
      expect(result.report, isNull);
    });

    test('reports a server failure for error responses', () async {
      final wttr = FakeWttr(statusCode: 500);

      final result = await wttr.service.refresh(
        server: server,
        zone: 'Nowhere',
      );

      expect(result.failure, WeatherFailure.server);
      expect(result.report, isNull);
    });

    test('reports a server failure for unreadable data', () async {
      final service = WeatherService(
        client: MockClient((_) async => http.Response('<html>', 200)),
      );

      final result = await service.refresh(server: server, zone: 'Berlin');

      expect(result.failure, WeatherFailure.server);
    });

    test('does not mix up cached locations', () async {
      final wttr = FakeWttr();
      await wttr.service.refresh(server: server, zone: 'Berlin');

      expect(
        await wttr.service.loadCached(server: server, zone: 'Tokyo'),
        isNull,
      );
    });
  });

  group('cache', () {
    test('keeps only the most recently fetched locations', () async {
      var minute = 0;
      final service = WeatherService(
        client: MockClient(
          (_) async => http.Response.bytes(utf8.encode(wttrBerlinFixture), 200),
        ),
        clock: () => DateTime(2026, 10, 3, 12, minute++),
      );

      for (var i = 0; i <= WeatherService.maxCachedLocations; i++) {
        await service.refresh(server: server, zone: 'City $i');
      }

      expect(await service.loadCached(server: server, zone: 'City 0'), isNull);
      expect(
        await service.loadCached(server: server, zone: 'City 1'),
        isNotNull,
      );
      expect(
        await service.loadCached(
          server: server,
          zone: 'City ${WeatherService.maxCachedLocations}',
        ),
        isNotNull,
      );
      final prefs = await SharedPreferences.getInstance();
      final cache = jsonDecode(prefs.getString(WeatherService.cacheKey)!);
      expect(cache, hasLength(WeatherService.maxCachedLocations));
    });

    test('has room for many favorites and widget cities', () async {
      expect(WeatherService.maxCachedLocations, greaterThanOrEqualTo(50));
      final service = WeatherService(
        client: MockClient(
          (_) async => http.Response.bytes(utf8.encode(wttrBerlinFixture), 200),
        ),
      );

      for (var i = 0; i < WeatherService.maxCachedLocations; i++) {
        await service.refresh(server: server, zone: 'City $i', lang: 'de');
      }

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(WeatherService.cacheKey)!;
      expect(jsonDecode(stored), hasLength(WeatherService.maxCachedLocations));
      expect(await service.loadCached(server: server, zone: 'City 0', lang: 'de'),
          isNotNull);
      // The full cache stays small enough to keep in the preferences.
      expect(utf8.encode(stored).length, lessThan(256 * 1024));
      printOnFailure('cache size: ${utf8.encode(stored).length} bytes');
    });

    test('keeps reports that finish downloading together', () async {
      final wttr = FakeWttr();

      await Future.wait([
        wttr.service.refresh(server: server, zone: 'Berlin'),
        wttr.service.refresh(server: server, zone: 'Tokyo'),
      ]);

      expect(
        await wttr.service.loadCached(server: server, zone: 'Berlin'),
        isNotNull,
      );
      expect(
        await wttr.service.loadCached(server: server, zone: 'Tokyo'),
        isNotNull,
      );
    });

    test('ignores a corrupted cache', () async {
      SharedPreferences.setMockInitialValues({
        WeatherService.cacheKey: 'not json',
      });

      expect(
        await FakeWttr().service.loadCached(server: server, zone: 'Berlin'),
        isNull,
      );
    });
  });

  group('sharing', () {
    test('concurrent refreshes of the same place share one download', () async {
      final wttr = FakeWttr()..hold = Completer();
      final first = wttr.service.refresh(server: server, zone: 'Berlin');
      final second = wttr.service.refresh(server: server, zone: 'Berlin');
      final other = wttr.service.refresh(server: server, zone: 'Tokyo');
      wttr.hold!.complete();
      await Future.wait([first, second, other]);

      expect(wttr.requests.map((uri) => uri.path), ['/Berlin', '/Tokyo']);
      await wttr.service.refresh(server: server, zone: 'Berlin');
      expect(wttr.requests, hasLength(3), reason: 'a later refresh downloads');
    });

    test('current() uses a recent cache and refreshes an old one', () async {
      final wttr = FakeWttr();
      await wttr.service.refresh(server: server, zone: 'Berlin');
      await wttr.service.current(server: server, zone: 'Berlin');
      expect(wttr.requests, hasLength(1));

      final hourAgo = DateTime.now().subtract(const Duration(hours: 1));
      await FakeWttr(
        clock: () => hourAgo,
      ).service.refresh(server: server, zone: 'Tokyo');
      final result = await wttr.service.current(server: server, zone: 'Tokyo');
      expect(wttr.requests.last.path, '/Tokyo');
      expect(result.isFresh, isTrue);
    });
  });

  group('cache per request', () {
    test('keeps reports of other languages and servers apart', () async {
      final wttr = FakeWttr();
      await wttr.service.refresh(server: server, zone: 'Berlin', lang: 'de');

      expect(
        await wttr.service.loadCached(
          server: server,
          zone: 'Berlin',
          lang: 'de',
        ),
        isNotNull,
      );
      expect(
        await wttr.service.loadCached(server: server, zone: 'Berlin'),
        isNull,
        reason: 'English is another request',
      );
      expect(
        await wttr.service.loadCached(
          server: 'https://example.org',
          zone: 'Berlin',
          lang: 'de',
        ),
        isNull,
        reason: 'another server is another request',
      );
    });

    test('current() downloads again after a language change', () async {
      final wttr = FakeWttr();
      await wttr.service.current(server: server, zone: 'Berlin', lang: 'de');
      await wttr.service.current(server: server, zone: 'Berlin');

      expect(wttr.requests.map((uri) => uri.queryParameters['lang']), [
        'de',
        null,
      ]);
    });

    test('offline, a report in another language is better than none', () async {
      final wttr = FakeWttr();
      await wttr.service.refresh(server: server, zone: 'Berlin', lang: 'de');
      wttr.offline = true;

      final result = await wttr.service.refresh(server: server, zone: 'Berlin');

      expect(result.failure, WeatherFailure.network);
      expect(result.report!.current.description, 'Wolkig');
    });

    test('offline, a report cached by version 1.10 is used', () async {
      // Version 1.10 cached the reports by zone alone.
      final wttr = FakeWttr(clock: () => DateTime(2026, 10, 3, 12));
      await wttr.service.refresh(server: server, zone: 'Berlin', lang: 'de');
      final prefs = await SharedPreferences.getInstance();
      final cache = jsonDecode(prefs.getString(WeatherService.cacheKey)!)
          as Map<String, dynamic>;
      await prefs.setString(WeatherService.cacheKey,
          jsonEncode({'Berlin': cache.values.single}));
      wttr.offline = true;

      final result = await wttr.service.refresh(server: server, zone: 'Berlin');
      expect(result.failure, WeatherFailure.network);
      expect(result.report!.current.description, 'Wolkig');
      expect(result.report!.fetchedAt, DateTime(2026, 10, 3, 12));

      final other = await wttr.service.refresh(server: server, zone: 'Paris');
      expect(other.report, isNull);
    });
  });
}
