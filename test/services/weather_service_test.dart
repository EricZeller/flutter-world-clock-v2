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
        WeatherService.buildUri('https://example.org', 'Washington, D.C.')
            .toString(),
        'https://example.org/Washington%2C%20D.C.?format=j1',
      );
    });
  });

  group('refresh', () {
    test('returns a fresh report and caches it', () async {
      final wttr = FakeWttr();

      final result =
          await wttr.service.refresh(server: server, zone: 'Berlin', lang: 'de');

      expect(result.isFresh, isTrue);
      expect(result.failure, isNull);
      expect(result.report!.current.description, 'Wolkig');
      expect(wttr.requests.single.queryParameters,
          {'format': 'j1', 'lang': 'de'});
      final cached = await wttr.service.loadCached('Berlin');
      expect(cached!.toJson(), result.report!.toJson());
    });

    test('falls back to the cache when offline', () async {
      final wttr = FakeWttr();
      final fresh =
          await wttr.service.refresh(server: server, zone: 'Berlin');
      wttr.offline = true;

      final result =
          await wttr.service.refresh(server: server, zone: 'Berlin');

      expect(result.failure, WeatherFailure.network);
      expect(result.isFresh, isFalse);
      expect(result.report!.toJson(), fresh.report!.toJson());
    });

    test('reports a network failure without cache', () async {
      final wttr = FakeWttr(offline: true);

      final result =
          await wttr.service.refresh(server: server, zone: 'Berlin');

      expect(result.failure, WeatherFailure.network);
      expect(result.report, isNull);
    });

    test('reports a server failure for error responses', () async {
      final wttr = FakeWttr(statusCode: 500);

      final result =
          await wttr.service.refresh(server: server, zone: 'Nowhere');

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

      expect(await wttr.service.loadCached('Tokyo'), isNull);
    });
  });

  group('cache', () {
    test('keeps only the most recently fetched locations', () async {
      var minute = 0;
      final service = WeatherService(
        client: MockClient((_) async =>
            http.Response.bytes(utf8.encode(wttrBerlinFixture), 200)),
        clock: () => DateTime(2026, 10, 3, 12, minute++),
      );

      for (var i = 0; i <= WeatherService.maxCachedLocations; i++) {
        await service.refresh(server: server, zone: 'City $i');
      }

      expect(await service.loadCached('City 0'), isNull);
      expect(await service.loadCached('City 1'), isNotNull);
      expect(
          await service.loadCached('City ${WeatherService.maxCachedLocations}'),
          isNotNull);
    });

    test('ignores a corrupted cache', () async {
      SharedPreferences.setMockInitialValues(
          {WeatherService.cacheKey: 'not json'});

      expect(await FakeWttr().service.loadCached('Berlin'), isNull);
    });
  });
}
