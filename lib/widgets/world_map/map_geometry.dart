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

  /// Diameter of a land dot on this canvas.
  double get dotDiameter => size.width / landMaskColumns * 0.62;
}

/// Centers of all land cells of the dot grid, decoded once.
final List<LatLng> landCells = () {
  final bits = base64Decode(landMaskBase64);
  return [
    for (var row = 0; row < landMaskRows; row++)
      for (var column = 0; column < landMaskColumns; column++)
        if (_isSet(bits, row * landMaskColumns + column))
          (
            latitude: landMaskNorth - (row + 0.5) * landMaskStep,
            longitude: -180 + (column + 0.5) * landMaskStep,
          ),
  ];
}();

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
