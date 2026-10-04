import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/widgets/world_map/land_mask.dart';
import 'package:world_clock_v2/widgets/world_map/world_map_data.dart';

/// Width divided by height of the (equirectangular) map.
const mapAspectRatio = 360 / (landMaskNorth - landMaskSouth);

typedef LatLng = ({double latitude, double longitude});

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

/// The point where the sun is directly overhead at [time]. Accurate to about
/// a degree, which is plenty for shading day and night.
LatLng subsolarPoint(DateTime time) {
  final utc = time.toUtc();
  final day = utc.difference(DateTime.utc(utc.year)).inMinutes / 1440;
  final declination = -23.44 * math.cos(2 * math.pi / 365 * (day + 10));
  // Equation of time in minutes: how far solar noon drifts from 12:00.
  final b = 2 * math.pi * (day - 81) / 364;
  final equationOfTime =
      9.87 * math.sin(2 * b) - 7.53 * math.cos(b) - 1.5 * math.sin(b);
  final hours = utc.hour + utc.minute / 60 + utc.second / 3600;
  var longitude = -15 * (hours - 12 + equationOfTime / 60);
  longitude = (longitude + 540) % 360 - 180;
  return (latitude: declination, longitude: longitude);
}

/// Sine of the sun's elevation above the horizon at [point].
double sunElevation(LatLng point, LatLng sun) {
  double rad(double degrees) => degrees * math.pi / 180;
  return math.sin(rad(point.latitude)) * math.sin(rad(sun.latitude)) +
      math.cos(rad(point.latitude)) *
          math.cos(rad(sun.latitude)) *
          math.cos(rad(point.longitude - sun.longitude));
}

enum Daylight { day, twilight, night }

/// Civil twilight ends when the sun is 6° below the horizon.
final _twilightLimit = -math.sin(6 * math.pi / 180);

Daylight daylightAt(LatLng point, LatLng sun) {
  final elevation = sunElevation(point, sun);
  if (elevation > 0) return Daylight.day;
  if (elevation > _twilightLimit) return Daylight.twilight;
  return Daylight.night;
}
