import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/widgets/world_map/map_geometry.dart';
import 'package:world_clock_v2/widgets/world_map/world_map_data.dart';

/// Draws the land dots, dimmed where it is night. Only repaints when the
/// minute, size or colors change; zooming merely scales the cached layer.
class LandPainter extends CustomPainter {
  LandPainter({required this.sun, required this.color});

  final LatLng sun;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final projection = MapProjection(size);
    final points = {
      for (final daylight in Daylight.values) daylight: <double>[],
    };
    for (final cell in landCells) {
      final offset = projection.project(cell);
      points[daylightAt(cell, sun)]!
        ..add(offset.dx)
        ..add(offset.dy);
    }

    const alphas = {
      Daylight.day: 0.5,
      Daylight.twilight: 0.3,
      Daylight.night: 0.14,
    };
    for (final MapEntry(key: daylight, value: coordinates) in points.entries) {
      canvas.drawRawPoints(
        ui.PointMode.points,
        Float32List.fromList(coordinates),
        Paint()
          ..color = color.withValues(alpha: alphas[daylight])
          ..strokeWidth = projection.dotDiameter
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant LandPainter oldDelegate) =>
      oldDelegate.sun != sun || oldDelegate.color != color;
}

/// Whether the name of [city] is drawn at the zoom level [scale].
bool isLabelVisible(City city, {required bool isSelected, required double scale}) {
  if (isSelected) return true;
  if (majorMapCities.contains(city.name) || city.isCustom) return scale >= 1.6;
  return scale >= 3;
}

/// Draws the city markers, their labels and the sun. Sizes are divided by
/// [scale] so they keep their size on screen while zooming.
class MarkerPainter extends CustomPainter {
  MarkerPainter({
    required this.cities,
    required this.selectedCity,
    required this.sun,
    required this.scale,
    required this.markerColor,
    required this.sunColor,
    required this.labelBackground,
    required this.labelColor,
  });

  final List<City> cities;
  final City selectedCity;
  final LatLng sun;
  final double scale;
  final Color markerColor;
  final Color sunColor;
  final Color labelBackground;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final projection = MapProjection(size);
    _paintSun(canvas, projection.project(sun));

    // Draw the selected city last so it is on top.
    final ordered = [
      ...cities.where((city) => city != selectedCity),
      ...cities.where((city) => city == selectedCity),
    ];
    for (final city in ordered) {
      final isSelected = city == selectedCity;
      final point = projection.project(cityPosition(city));
      _paintMarker(canvas, point, city, isSelected);
      if (isLabelVisible(city, isSelected: isSelected, scale: scale)) {
        _paintLabel(canvas, point, city.name, isSelected);
      }
    }
  }

  /// A small sun with rays, so it cannot be mistaken for a city marker.
  void _paintSun(Canvas canvas, Offset point) {
    final unit = 1 / scale;
    canvas.drawCircle(point, 18 * unit,
        Paint()..color = sunColor.withValues(alpha: 0.18));
    canvas.drawCircle(point, 5.5 * unit, Paint()..color = sunColor);
    final rays = Paint()
      ..color = sunColor
      ..strokeWidth = 2 * unit
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final direction = Offset.fromDirection(i * math.pi / 4);
      canvas.drawLine(
          point + direction * 8.5 * unit, point + direction * 12 * unit, rays);
    }
  }

  void _paintMarker(Canvas canvas, Offset point, City city, bool isSelected) {
    final unit = 1 / scale;
    final radius = (isSelected ? 6.0 : city.isCustom ? 5.0 : 3.5) * unit;
    if (isSelected) {
      canvas.drawCircle(point, 14 * unit,
          Paint()..color = markerColor.withValues(alpha: 0.25));
    }
    canvas.drawCircle(
        point, radius + 1.5 * unit, Paint()..color = labelBackground);
    canvas.drawCircle(
      point,
      radius,
      Paint()
        ..color = isSelected
            ? markerColor
            : markerColor.withValues(alpha: city.isCustom ? 0.9 : 0.75),
    );
  }

  void _paintLabel(Canvas canvas, Offset point, String name, bool isSelected) {
    final label = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          color: labelColor,
          fontSize: (isSelected ? 13 : 11) / scale,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 140 / scale);

    final padding = EdgeInsets.symmetric(
        horizontal: 5 / scale, vertical: 2 / scale);
    final topLeft = point + Offset(8 / scale, -label.height / 2 - padding.top);
    final bubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(topLeft.dx, topLeft.dy, label.width + padding.horizontal,
          label.height + padding.vertical),
      Radius.circular(6 / scale),
    );
    canvas.drawRRect(
      bubble,
      Paint()
        ..color = labelBackground.withValues(alpha: isSelected ? 0.9 : 0.7),
    );
    label.paint(canvas, topLeft + Offset(padding.left, padding.top));
  }

  @override
  bool shouldRepaint(covariant MarkerPainter oldDelegate) =>
      oldDelegate.cities != cities ||
      oldDelegate.selectedCity != selectedCity ||
      oldDelegate.sun != sun ||
      oldDelegate.scale != scale ||
      oldDelegate.markerColor != markerColor ||
      oldDelegate.labelBackground != labelBackground;
}
