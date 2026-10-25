import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/widgets/world_map/land_mask.dart';
import 'package:world_clock_v2/widgets/world_map/map_geometry.dart';

void main() {
  group('MapProjection', () {
    const projection = MapProjection(Size(2500, 1000));

    test('maps the corners and the equator', () {
      expect(
        projection.project((latitude: landMaskNorth, longitude: -180)),
        Offset.zero,
      );
      expect(
        projection.project((latitude: landMaskSouth, longitude: 180)),
        const Offset(2500, 1000),
      );
      final equator = projection.project((latitude: 0, longitude: 0));
      expect(equator.dx, 1250);
      expect(equator.dy, closeTo(1000 * 84 / 144, 0.001));
    });

    test('keeps the proportions of the map', () {
      expect(mapAspectRatio, 2.5);
    });
  });

  group('landCells', () {
    bool isLand(double latitude, double longitude) => landCells.any(
      (cell) =>
          (cell.latitude - latitude).abs() <= landMaskStep / 2 &&
          (cell.longitude - longitude).abs() <= landMaskStep / 2,
    );

    test('contains continents but not oceans', () {
      expect(isLand(52.5, 13.4), isTrue, reason: 'Berlin');
      expect(isLand(-15.8, -47.9), isTrue, reason: 'Brasília');
      expect(isLand(-25.0, 135.0), isTrue, reason: 'Australia');
      expect(isLand(30.0, -40.0), isFalse, reason: 'Atlantic');
      expect(isLand(0.0, -150.0), isFalse, reason: 'Pacific');
    });

    test('covers about a third of the map', () {
      final share = landCells.length / (landMaskColumns * landMaskRows);
      expect(share, inInclusiveRange(0.25, 0.4));
    });
  });

  group('dotDiameter', () {
    const projection = MapProjection(Size(3000, 1200));

    test('is 62% of a cell at the zoom level the grid is drawn from', () {
      expect(projection.dotDiameter(), closeTo(3000 / 300 * 0.62, 0.001));
      expect(projection.dotDiameter(grid: LandGrid.fine, scale: fineLandFrom),
          closeTo(3000 / 900 * 0.62, 0.001));
    });

    test('shrinks on the map as the zoom grows, growing on screen', () {
      final at3 = projection.dotDiameter(grid: LandGrid.fine, scale: 3);
      final at12 = projection.dotDiameter(grid: LandGrid.fine, scale: 12);
      expect(at12, closeTo(at3 / 2, 0.001), reason: 'half on the map');
      expect(at12 * 12, closeTo(at3 * 3 * 2, 0.01), reason: 'twice on screen');
    });
  });

  group('LandGrid', () {
    bool isLand(LandGrid grid, double latitude, double longitude) =>
        grid.cells.any(
          (cell) =>
              (cell.latitude - latitude).abs() <= grid.step / 2 &&
              (cell.longitude - longitude).abs() <= grid.step / 2,
        );

    test('is coarse for the whole map and fine when zoomed in', () {
      expect(LandGrid.at(1), LandGrid.coarse);
      expect(LandGrid.at(fineLandFrom - 0.1), LandGrid.coarse);
      expect(LandGrid.at(fineLandFrom), LandGrid.fine);
      expect(LandGrid.at(20), LandGrid.fine);
      expect(
        LandGrid.fine.step * 3,
        closeTo(LandGrid.coarse.step, 0.001),
        reason: 'the fine dots are as big at 3x as the coarse ones at 1x',
      );
    });

    test('decodes the cells with their sines and cosines, in bands', () {
      final cells = LandGrid.coarse.data;
      expect(cells.length, landCells.length);
      expect(cells.centers, landCells);
      for (var i = 0; i < cells.length; i += 97) {
        expect(cells.sinLatitudes[i],
            closeTo(math.sin(cells.latitudes[i] * math.pi / 180), 1e-9));
        expect(cells.cosLongitudes[i],
            closeTo(math.cos(cells.longitudes[i] * math.pi / 180), 1e-9));
      }
      expect(cells.bandStarts.first, 0);
      expect(cells.bandStarts.last, cells.length);
      // Bands of whole rows: 8 rows of 1.2 degrees.
      final rowsPerBand = (LandCells.bandDegrees / landMaskStep).round();
      final bandHeight = rowsPerBand * landMaskStep;
      expect(cells.bandStarts.length - 1, (landMaskRows / rowsPerBand).ceil());
      for (var band = 0; band < cells.bandStarts.length - 1; band++) {
        for (var i = cells.bandStarts[band]; i < cells.bandStarts[band + 1];
            i++) {
          expect(
              cells.latitudes[i],
              inInclusiveRange(landMaskNorth - (band + 1) * bandHeight,
                  landMaskNorth - band * bandHeight),
              reason: 'cell $i in band $band');
        }
      }
    });

    test('the fine grid shows the same continents, in more detail', () {
      expect(isLand(LandGrid.fine, 52.5, 13.4), isTrue, reason: 'Berlin');
      expect(isLand(LandGrid.fine, -25.0, 135.0), isTrue, reason: 'Australia');
      expect(isLand(LandGrid.fine, 30.0, -40.0), isFalse, reason: 'Atlantic');
      expect(isLand(LandGrid.fine, 47.66, 9.18), isTrue, reason: 'Konstanz');
      expect(
        isLand(LandGrid.fine, 54.0, 8.0),
        isFalse,
        reason: 'the North Sea off Germany, land in the coarse grid',
      );
      final share =
          LandGrid.fine.cells.length /
          (LandGrid.fine.columns * LandGrid.fine.rows);
      expect(share, inInclusiveRange(0.25, 0.4));
      expect(
        LandGrid.fine.cells.length,
        greaterThan(LandGrid.coarse.cells.length * 8),
      );
    });
  });

  group('cityPosition', () {
    test('uses coordinates of the city or of its time zone', () {
      expect(cityPosition(City.berlin), (latitude: 52.52, longitude: 13.40));
      const custom = City(
        name: 'Home',
        country: '',
        timeZone: 'Europe/Berlin',
        flag: '',
        utc: '+02:00',
        weatherZone: 'Home',
        latitude: 48.1,
        longitude: 11.6,
        isCustom: true,
      );
      expect(cityPosition(custom), (latitude: 48.1, longitude: 11.6));
    });
  });

  group('sun', () {
    test('is over the tropic of cancer at the June solstice noon', () {
      final sun = subsolarPoint(DateTime.utc(2026, 6, 21, 12));
      expect(sun.latitude, closeTo(23.44, 0.5));
      expect(sun.longitude, closeTo(0, 1.5));
    });

    test('is over the equator at the March equinox', () {
      final sun = subsolarPoint(DateTime.utc(2026, 3, 20, 18));
      expect(sun.latitude, closeTo(0, 1.5));
      expect(sun.longitude, closeTo(-90, 2.5));
    });

    test('moves 15 degrees west per hour', () {
      final first = subsolarPoint(DateTime.utc(2026, 10, 3, 10));
      final second = subsolarPoint(DateTime.utc(2026, 10, 3, 11));
      expect(first.longitude - second.longitude, closeTo(15, 0.1));
    });

    test('tells day, twilight and night apart', () {
      // 2026-10-03 12:00 UTC: midday in Europe, night in the Pacific.
      final sun = subsolarPoint(DateTime.utc(2026, 10, 3, 12));
      expect(daylightAt((latitude: 52.5, longitude: 13.4), sun), Daylight.day);
      expect(
        daylightAt((latitude: 35.7, longitude: 139.7), sun),
        Daylight.night,
        reason: 'Tokyo at 21:00',
      );
      // About 3° beyond the terminator along the equator.
      expect(
        daylightAt((latitude: 0, longitude: sun.longitude + 93), sun),
        Daylight.twilight,
      );
    });
  });
}
