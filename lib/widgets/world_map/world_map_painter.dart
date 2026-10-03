import 'package:flutter/material.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/widgets/world_map/world_map_data.dart';

class DotMatrixWorldMapPainter extends CustomPainter {
  DotMatrixWorldMapPainter({
    required this.cities,
    required this.selectedCity,
    required this.scale,
    required this.color,
    required this.markerColor,
    required this.labelBackground,
    required this.labelColor,
  });

  final List<City> cities;
  final City selectedCity;
  final double scale;
  final Color color;
  final Color markerColor;
  final Color labelBackground;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    // --- 1. HOCHAUFLÖSENDES DOT MATRIX RASTER ---
    final landDotPaint = Paint()
      ..color = color.withValues(alpha: 0.32)
      ..style = PaintingStyle.fill;

    const cols = 120;
    const rows = 90;

    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;
    final dotRadius = (cellWidth < cellHeight ? cellWidth : cellHeight) * 0.38;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final lat = 90.0 - (r + 0.5) * (180.0 / rows);
        final lon = (c + 0.5) * (360.0 / cols) - 180.0;

        if (_isLand(lat, lon)) {
          final x = (c + 0.5) * cellWidth;
          final y = (r + 0.5) * cellHeight;
          canvas.drawCircle(Offset(x, y), dotRadius, landDotPaint);
        }
      }
    }

    // --- 2. DYNAMISCHE STÄDTE-MARKER ---
    final showAllMarkers = scale >= 2.4;
    final showLabels = scale >= 5.2;

    for (final city in cities) {
      final isSelected = city == selectedCity;
      final isMajor = majorMapCities.contains(city.name) || city.isCustom;

      // Wenn herausgezoomt: Nur Hauptstädte/Auswahl anzeigen
      if (!showAllMarkers && !isMajor && !isSelected) continue;

      final point = projectCity(city, size);

      // Äußerer Puls-Effekt für selektierte Stadt
      if (isSelected || city.isCustom) {
        canvas.drawCircle(
          point,
          (city.isCustom ? 14 : 10) / scale.clamp(1.0, 2.0),
          Paint()..color = markerColor.withValues(alpha: 0.25),
        );
      }

      // Hintergrund-Schutzring
      canvas.drawCircle(
        point,
        (city.isCustom ? 6 : 4.5) / scale.clamp(1.0, 2.0),
        Paint()..color = labelBackground,
      );

      // Marker Rand
      canvas.drawCircle(
        point,
        (city.isCustom ? 5 : 3.5) / scale.clamp(1.0, 2.0),
        Paint()
          ..color = markerColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 / scale.clamp(1.0, 2.0),
      );

      // Marker Zentrum
      canvas.drawCircle(
        point,
        (city.isCustom ? 3.5 : 2.0) / scale.clamp(1.0, 2.0),
        Paint()
          ..color = isSelected ? markerColor : markerColor.withValues(alpha: 0.85)
          ..style = PaintingStyle.fill,
      );

      // --- 3. LABELS UND NORMALE STÄDTENAMEN ---
      if (showLabels || isSelected) {
        // Noch kleinere Basisschriftgröße (7.0pt / 8.5pt) + stärkere Skalierung beim Zoomen
        final baseFontSize = isSelected ? 8.5 : 7.0;
        final dynamicFontSize = (baseFontSize / (scale * 0.85)).clamp(1.5, baseFontSize);

        final label = TextPainter(
          text: TextSpan(
            text: city.name,
            style: TextStyle(
              color: labelColor,
              fontSize: dynamicFontSize,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: size.width * .10); // Maximale Breite auf 10% reduziert

        // Minimale Paddings & sehr nah am Marker positioniert
        final paddingX = (2.5 / scale).clamp(0.8, 2.5);
        final paddingY = (1.2 / scale).clamp(0.5, 1.2);
        final offsetX = (4.0 / scale).clamp(1.5, 4.0);
        final offsetY = (-10.0 / scale).clamp(-10.0, -3.0);

        final bubble = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            point.dx + offsetX - paddingX / 2,
            point.dy + offsetY - paddingY / 2,
            label.width + paddingX * 2,
            label.height + paddingY * 2,
          ),
          Radius.circular((2.0 / scale).clamp(0.8, 2.0)),
        );

        canvas.drawRRect(
          bubble,
          Paint()..color = labelBackground.withValues(alpha: isSelected ? 0.85 : 0.45),
        );

        label.paint(canvas, point + Offset(offsetX, offsetY));
      }
    }
  }

  bool _isLand(double lat, double lon) {
    for (final polygon in continentPolygons) {
      if (_pointInPolygon(lat, lon, polygon)) return true;
    }
    return false;
  }

  bool _pointInPolygon(double lat, double lon, List<List<double>> polygon) {
    var inside = false;
    var j = polygon.length - 1;
    for (var i = 0; i < polygon.length; i++) {
      final pi = polygon[i];
      final pj = polygon[j];
      final yi = pi[0], xi = pi[1];
      final yj = pj[0], xj = pj[1];

      final intersect = ((yi > lat) != (yj > lat)) &&
          (lon < (xj - xi) * (lat - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
      j = i;
    }
    return inside;
  }

  @override
  bool shouldRepaint(covariant DotMatrixWorldMapPainter oldDelegate) =>
      oldDelegate.cities != cities ||
      oldDelegate.selectedCity != selectedCity ||
      oldDelegate.scale != scale ||
      oldDelegate.color != color ||
      oldDelegate.labelBackground != labelBackground;
}

Offset projectCity(City city, Size size) {
  if (city.latitude != null && city.longitude != null) {
    return _projectLatLon(city.latitude!, city.longitude!, size);
  }
  final point = timeZoneCoordinates[city.timeZone] ?? regionPoint(city.timeZone);
  return _projectLatLon(point.$1, point.$2, size);
}

Offset _projectLatLon(double latitude, double longitude, Size size) {
  final x = (longitude + 180) / 360 * size.width;
  final y = (90 - latitude) / 180 * size.height;
  return Offset(x, y);
}
