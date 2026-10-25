import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/widgets/world_map/land_mask.dart';
import 'package:world_clock_v2/widgets/world_map/map_geometry.dart';

/// Draws the land dots, dimmed where it is night. Repaints when the minute,
/// size, colors or zoom level change; panning merely moves the cached
/// layer. From [fineLandFrom] on the fine grid is drawn, so the dots stay
/// dots instead of growing into blobs, see [MapProjection.dotDiameter].
///
/// The dots are drawn in bands of [LandCells.bandDegrees], so that the
/// bands off screen are skipped when the map is zoomed in.
class LandPainter extends CustomPainter {
  LandPainter({required this.sun, required this.color, required this.scale});

  final LatLng sun;
  final Color color;
  final double scale;

  LandGrid get grid => LandGrid.at(scale);

  /// Coordinates of the dots of a band by daylight, reused between paints.
  static final _buffers = <LandGrid, List<Float32List>>{};

  @override
  void paint(Canvas canvas, Size size) {
    final grid = this.grid;
    final cells = grid.data;
    final buffers = _buffers.putIfAbsent(grid, () {
      final longest = Iterable.generate(
        cells.bandStarts.length - 1,
        (i) => cells.bandStarts[i + 1] - cells.bandStarts[i],
      ).fold(0, math.max);
      return [for (final _ in Daylight.values) Float32List(2 * longest)];
    });
    final paints = [
      for (final daylight in Daylight.values)
        Paint()
          ..color = color.withValues(alpha: _alphas[daylight]!)
          ..strokeWidth = MapProjection(
            size,
          ).dotDiameter(grid: grid, scale: scale)
          ..strokeCap = StrokeCap.round,
    ];

    // The sun's elevation at a cell, like sunElevation, from the sines and
    // cosines decoded with the cells.
    final sinSun = math.sin(sun.latitude * math.pi / 180);
    final cosSun = math.cos(sun.latitude * math.pi / 180);
    final sinSunLon = math.sin(sun.longitude * math.pi / 180);
    final cosSunLon = math.cos(sun.longitude * math.pi / 180);
    final xPerDegree = size.width / 360;
    final yPerDegree = size.height / (landMaskNorth - landMaskSouth);

    for (var band = 0; band < cells.bandStarts.length - 1; band++) {
      final lengths = List.filled(Daylight.values.length, 0);
      for (var i = cells.bandStarts[band]; i < cells.bandStarts[band + 1]; i++) {
        final elevation =
            cells.sinLatitudes[i] * sinSun +
            cells.cosLatitudes[i] *
                cosSun *
                (cells.cosLongitudes[i] * cosSunLon +
                    cells.sinLongitudes[i] * sinSunLon);
        final daylight = elevation > 0
            ? Daylight.day
            : elevation > twilightLimit
                ? Daylight.twilight
                : Daylight.night;
        final buffer = buffers[daylight.index];
        final at = lengths[daylight.index];
        buffer[at] = (cells.longitudes[i] + 180) * xPerDegree;
        buffer[at + 1] = (landMaskNorth - cells.latitudes[i]) * yPerDegree;
        lengths[daylight.index] = at + 2;
      }
      for (final daylight in Daylight.values) {
        if (lengths[daylight.index] == 0) continue;
        canvas.drawRawPoints(
          ui.PointMode.points,
          Float32List.sublistView(
            buffers[daylight.index],
            0,
            lengths[daylight.index],
          ),
          paints[daylight.index],
        );
      }
    }
  }

  static const _alphas = {
    Daylight.day: 0.5,
    Daylight.twilight: 0.3,
    Daylight.night: 0.14,
  };

  @override
  bool shouldRepaint(covariant LandPainter oldDelegate) =>
      oldDelegate.sun != sun ||
      oldDelegate.color != color ||
      oldDelegate.scale != scale;
}

/// Whether the marker of [city] is drawn at the zoom level [scale]: those
/// of smaller cities only once the map is zoomed in, so that 800 cities do
/// not cover the continents. Selected and custom cities are always drawn.
bool isMarkerVisible(
  City city, {
  required bool isSelected,
  required double scale,
}) => isSelected || city.isCustom || isBigCity(city) || scale >= 2;

/// A city of at least [bigCityPopulation] inhabitants or a capital; also a
/// city of an older version, whose population is unknown.
bool isBigCity(City city) =>
    city.isCapital ||
    city.population == null ||
    city.population! >= bigCityPopulation;

/// Whether the name of [city] is drawn at the zoom level [scale]: the
/// bigger the city, the sooner; capitals like big cities. Custom cities
/// count as metropolises; a city of an older version without a population
/// as a small one.
bool isLabelVisible(
  City city, {
  required bool isSelected,
  required double scale,
}) {
  if (isSelected) return true;
  if (city.isCustom) return scale >= 1.6;
  final population = city.population ?? 0;
  if (population >= metropolisPopulation) return scale >= 1.6;
  if (population >= bigCityPopulation || city.isCapital) return scale >= 3;
  return scale >= 5;
}

/// Cities of this size are labeled when the map is zoomed in a little.
const metropolisPopulation = 5000000;

/// Cities of this size are labeled at a medium zoom and have markers at
/// every zoom; smaller ones are labeled only when zoomed in far.
const bigCityPopulation = 1000000;

/// Draws the city markers and their labels. Sizes are divided by [scale] so
/// they keep their size on screen while zooming.
class MarkerPainter extends CustomPainter {
  MarkerPainter({
    required this.cities,
    required this.selectedCities,
    this.highlighted,
    required this.nameOf,
    required this.language,
    required this.scale,
    required this.markerColor,
    required this.labelBackground,
    required this.labelColor,
  });

  final List<City> cities;
  final Set<City> selectedCities;

  /// The city last tapped, drawn like a selected one until it is added.
  final City? highlighted;

  /// The name a city is labeled with, in the app's language [language].
  final String Function(City) nameOf;
  final String language;
  final double scale;
  final Color markerColor;
  final Color labelBackground;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final projection = MapProjection(size);
    // Draw the selected cities last so they are on top.
    final ordered = [
      ...cities.where((city) => !selectedCities.contains(city)),
      ...cities.where(selectedCities.contains),
    ];
    for (final city in ordered) {
      final isSelected = selectedCities.contains(city) || city == highlighted;
      if (!isMarkerVisible(city, isSelected: isSelected, scale: scale)) {
        continue;
      }
      final point = projection.project(cityPosition(city));
      _paintMarker(canvas, point, city, isSelected);
      if (isLabelVisible(city, isSelected: isSelected, scale: scale)) {
        _paintLabel(canvas, point, nameOf(city), isSelected);
      }
    }
  }

  void _paintMarker(Canvas canvas, Offset point, City city, bool isSelected) {
    final unit = 1 / scale;
    final radius =
        (isSelected
            ? 6.0
            : city.isCustom
            ? 5.0
            : isBigCity(city)
            ? 3.5
            : 2.5) *
        unit;
    if (isSelected) {
      canvas.drawCircle(
        point,
        14 * unit,
        Paint()..color = markerColor.withValues(alpha: 0.25),
      );
    }
    canvas.drawCircle(
      point,
      radius + 1.5 * unit,
      Paint()..color = labelBackground,
    );
    canvas.drawCircle(
      point,
      radius,
      Paint()
        ..color = isSelected
            ? markerColor
            : markerColor.withValues(alpha: city.isCustom ? 0.9 : 0.75),
    );
  }

  /// Laid-out labels by name, selection and color: laying out the names of
  /// hundreds of cities on every zoom step would stutter. The labels are
  /// laid out at screen size and drawn scaled, so the zoom level does not
  /// matter.
  static final _labels = <String, TextPainter>{};

  void _paintLabel(Canvas canvas, Offset point, String name, bool isSelected) {
    if (_labels.length > 4000) _labels.clear();
    final label = _labels.putIfAbsent(
      '$isSelected|${labelColor.toARGB32()}|$name',
      () => TextPainter(
        text: TextSpan(
          text: name,
          style: TextStyle(
            color: labelColor,
            fontSize: isSelected ? 13 : 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 140),
    );

    const padding = EdgeInsets.symmetric(horizontal: 5, vertical: 2);
    final topLeft = Offset(8, -label.height / 2 - padding.top);
    final bubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        topLeft.dx,
        topLeft.dy,
        label.width + padding.horizontal,
        label.height + padding.vertical,
      ),
      const Radius.circular(6),
    );
    canvas
      ..save()
      ..translate(point.dx, point.dy)
      ..scale(1 / scale)
      ..drawRRect(
        bubble,
        Paint()
          ..color = labelBackground.withValues(alpha: isSelected ? 0.9 : 0.7),
      );
    label.paint(canvas, topLeft + Offset(padding.left, padding.top));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MarkerPainter oldDelegate) =>
      oldDelegate.cities != cities ||
      !setEquals(oldDelegate.selectedCities, selectedCities) ||
      oldDelegate.highlighted != highlighted ||
      oldDelegate.scale != scale ||
      oldDelegate.language != language ||
      oldDelegate.markerColor != markerColor ||
      oldDelegate.labelBackground != labelBackground ||
      oldDelegate.labelColor != labelColor;
}
