import 'dart:math' as math;

typedef LatLng = ({double latitude, double longitude});

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

/// Civil twilight ends when the sun is 6° below the horizon: the sine of
/// the elevation below which it is night.
final twilightLimit = -math.sin(6 * math.pi / 180);

Daylight daylightAt(LatLng point, LatLng sun) {
  final elevation = sunElevation(point, sun);
  if (elevation > 0) return Daylight.day;
  if (elevation > twilightLimit) return Daylight.twilight;
  return Daylight.night;
}

/// Whether the sun is below the horizon at [point] at [time].
bool isNightAt(LatLng point, DateTime time) =>
    sunElevation(point, subsolarPoint(time)) < 0;
