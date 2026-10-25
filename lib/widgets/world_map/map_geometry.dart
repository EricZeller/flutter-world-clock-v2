import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/utils/sun.dart';
import 'package:world_clock_v2/widgets/world_map/land_mask.dart';
import 'package:world_clock_v2/widgets/world_map/world_map_data.dart';

export 'package:world_clock_v2/utils/sun.dart';

/// Width divided by height of the (equirectangular) map.
const mapAspectRatio = 360 / (landMaskNorth - landMaskSouth);

/// Equirectangular projection of the map area onto a canvas of [size].
class MapProjection {
  const MapProjection(this.size);

  final Size size;

  Offset project(LatLng point) => Offset(
    (point.longitude + 180) / 360 * size.width,
    (landMaskNorth - point.latitude) /
        (landMaskNorth - landMaskSouth) *
        size.height,
  );

  /// Diameter of a land dot of [grid] on this canvas at the zoom level
  /// [scale]: 62% of a cell at the zoom level the grid is drawn from, then
  /// growing with the square root of the zoom, so that dots zoomed in far
  /// stay dots rather than blobs, but do not vanish between them either.
  double dotDiameter({LandGrid grid = LandGrid.coarse, double scale = 1}) =>
      size.width / grid.columns * 0.62 * math.sqrt(grid.drawnFrom / scale);
}

/// The dot grid of the map: the coarse one as a whole, the fine one from
/// [fineLandFrom] on, where the coarse dots would have grown into blobs.
class LandGrid {
  const LandGrid._(this.step, this.columns, this.rows, this._base64);

  static const coarse = LandGrid._(
    landMaskStep,
    landMaskColumns,
    landMaskRows,
    landMaskBase64,
  );
  static const fine = LandGrid._(
    landMaskFineStep,
    landMaskFineColumns,
    landMaskFineRows,
    landMaskFineBase64,
  );

  /// The grid drawn at the zoom level [scale].
  static LandGrid at(double scale) => scale >= fineLandFrom ? fine : coarse;

  final double step;
  final int columns;
  final int rows;
  final String _base64;

  /// The zoom level the grid is drawn from.
  double get drawnFrom => this == fine ? fineLandFrom : 1;

  static final _data = <LandGrid, LandCells>{};

  /// The land cells, decoded once.
  LandCells get data => _data.putIfAbsent(this, () => LandCells._(this));

  /// Centers of all land cells.
  List<LatLng> get cells => data.centers;
}

/// The land cells of a [LandGrid] as typed arrays, row by row from the
/// north, with what shading them needs ready: the sines and cosines of
/// their coordinates, so that the sun's elevation at a cell is a few
/// multiplications, and the first cell of each band of [bandDegrees].
class LandCells {
  LandCells._(LandGrid grid) {
    final bits = base64Decode(grid._base64);
    var count = 0;
    for (var index = 0; index < grid.columns * grid.rows; index++) {
      if (_isSet(bits, index)) count++;
    }
    length = count;
    latitudes = Float64List(count);
    longitudes = Float64List(count);
    sinLatitudes = Float64List(count);
    cosLatitudes = Float64List(count);
    sinLongitudes = Float64List(count);
    cosLongitudes = Float64List(count);
    final rowsPerBand = (bandDegrees / grid.step).round();
    final starts = <int>[];
    var cell = 0;
    for (var row = 0; row < grid.rows; row++) {
      if (row % rowsPerBand == 0) starts.add(cell);
      final latitude = landMaskNorth - (row + 0.5) * grid.step;
      for (var column = 0; column < grid.columns; column++) {
        if (!_isSet(bits, row * grid.columns + column)) continue;
        final longitude = -180 + (column + 0.5) * grid.step;
        latitudes[cell] = latitude;
        longitudes[cell] = longitude;
        sinLatitudes[cell] = math.sin(latitude * math.pi / 180);
        cosLatitudes[cell] = math.cos(latitude * math.pi / 180);
        sinLongitudes[cell] = math.sin(longitude * math.pi / 180);
        cosLongitudes[cell] = math.cos(longitude * math.pi / 180);
        cell++;
      }
    }
    starts.add(cell);
    bandStarts = starts;
  }

  /// The height of the bands the dots are drawn in, so that the bands off
  /// screen can be skipped when the map is zoomed in.
  static const bandDegrees = 10.0;

  late final int length;
  late final Float64List latitudes;
  late final Float64List longitudes;
  late final Float64List sinLatitudes;
  late final Float64List cosLatitudes;
  late final Float64List sinLongitudes;
  late final Float64List cosLongitudes;

  /// The index of the first cell of each band, and [length] at the end.
  late final List<int> bandStarts;

  List<LatLng>? _centers;

  List<LatLng> get centers => _centers ??= [
    for (var i = 0; i < length; i++)
      (latitude: latitudes[i], longitude: longitudes[i]),
  ];
}

/// The zoom level from which the fine dot grid is drawn: its dots are then
/// as big on screen as the coarse ones are without zoom.
const fineLandFrom = 3.0;

/// Centers of all land cells of the coarse dot grid.
List<LatLng> get landCells => LandGrid.coarse.cells;

bool _isSet(Uint8List bits, int index) =>
    bits[index >> 3] & (1 << (index & 7)) != 0;

/// Position of [city] on the map: its own coordinates if known, otherwise
/// the location of its time zone.
LatLng cityPosition(City city) {
  if (city.latitude != null && city.longitude != null) {
    return (latitude: city.latitude!, longitude: city.longitude!);
  }
  final (latitude, longitude) =
      timeZoneCoordinates[city.timeZone] ?? regionPoint(city.timeZone);
  return (latitude: latitude, longitude: longitude);
}
