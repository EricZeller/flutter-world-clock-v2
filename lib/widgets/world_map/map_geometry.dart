import 'dart:convert';
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

  /// Diameter of a land dot of a grid of [columns] on this canvas.
  double dotDiameter([int columns = landMaskColumns]) =>
      size.width / columns * 0.62;
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

  static final _cells = <LandGrid, List<LatLng>>{};

  /// Centers of all land cells, decoded once.
  List<LatLng> get cells => _cells.putIfAbsent(this, () {
    final bits = base64Decode(_base64);
    return [
      for (var row = 0; row < rows; row++)
        for (var column = 0; column < columns; column++)
          if (_isSet(bits, row * columns + column))
            (
              latitude: landMaskNorth - (row + 0.5) * step,
              longitude: -180 + (column + 0.5) * step,
            ),
    ];
  });
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
