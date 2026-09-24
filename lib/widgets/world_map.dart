import 'package:flutter/material.dart';
import 'package:world_clock_v2/pages/location.dart';

class WorldMap extends StatefulWidget {
  const WorldMap({
    super.key,
    required this.cities,
    required this.selectedCity,
    required this.onCityTap,
  });

  final List<City> cities;
  final City selectedCity;
  final ValueChanged<City> onCityTap;

  @override
  State<WorldMap> createState() => _WorldMapState();
}

class _WorldMapState extends State<WorldMap> {
  final _controller = TransformationController();
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final scale = _controller.value.getMaxScaleOnAxis();
      if ((scale - _scale).abs() > .05) setState(() => _scale = scale);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mapHeight = constraints.maxHeight;
        final mapWidth = constraints.maxWidth;

        return InteractiveViewer(
          transformationController: _controller,
          minScale: 1.0,
          maxScale: 25.0,
          boundaryMargin: const EdgeInsets.all(100),
          child: SizedBox(
            width: mapWidth,
            height: mapHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final size = Size(mapWidth, mapHeight);
                final city = _nearestCity(details.localPosition, size);
                if (city != null) widget.onCityTap(city);
              },
              child: CustomPaint(
                painter: _DotMatrixWorldMapPainter(
                  cities: widget.cities,
                  selectedCity: widget.selectedCity,
                  scale: _scale,
                  color: Theme.of(context).colorScheme.primary,
                  markerColor: Theme.of(context).colorScheme.secondary,
                  labelBackground: Theme.of(context).colorScheme.inverseSurface,
                  labelColor: Theme.of(context).colorScheme.onInverseSurface,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
      },
    );
  }

  City? _nearestCity(Offset position, Size size) {
    City? nearest;
    var distance = 28.0 / _scale.clamp(1.0, 2.5);
    for (final city in widget.cities) {
      final point = _project(city, size);
      final current = (point - position).distance;
      if (current < distance) {
        distance = current;
        nearest = city;
      }
    }
    return nearest;
  }
}

class _DotMatrixWorldMapPainter extends CustomPainter {
  _DotMatrixWorldMapPainter({
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
      final isMajor = _majorCities.contains(city.name) || city.isCustom;

      // Wenn herausgezoomt: Nur Hauptstädte/Auswahl anzeigen
      if (!showAllMarkers && !isMajor && !isSelected) continue;

      final point = _project(city, size);

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
    for (final polygon in _continents) {
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
  bool shouldRepaint(covariant _DotMatrixWorldMapPainter oldDelegate) =>
      oldDelegate.cities != cities ||
      oldDelegate.selectedCity != selectedCity ||
      oldDelegate.scale != scale ||
      oldDelegate.color != color ||
      oldDelegate.labelBackground != labelBackground;
}

Offset _project(City city, Size size) {
  if (city.latitude != null && city.longitude != null) {
    return _projectLatLon(city.latitude!, city.longitude!, size);
  }
  final point = _zonePoints[city.timeZone] ?? _regionPoint(city.timeZone);
  return _projectLatLon(point.$1, point.$2, size);
}

Offset _projectLatLon(double latitude, double longitude, Size size) {
  final x = (longitude + 180) / 360 * size.width;
  final y = (90 - latitude) / 180 * size.height;
  return Offset(x, y);
}

(double, double) _regionPoint(String zone) {
  if (zone.startsWith('America/')) return (25, -95);
  if (zone.startsWith('Europe/')) return (50, 15);
  if (zone.startsWith('Africa/')) return (5, 20);
  if (zone.startsWith('Asia/')) return (35, 100);
  if (zone.startsWith('Australia/')) return (-25, 135);
  return (0, 0);
}

/// Hauptstädte/Metropolen, die auch uneingezoomt sichtbar bleiben
const Set<String> _majorCities = {
  'Berlin', 'London', 'Paris', 'New York', 'Tokyo', 'Sydney', 'Cairo',
  'Beijing', 'Moscow', 'Rio de Janeiro', 'Buenos Aires', 'Los Angeles',
  'Chicago', 'Delhi', 'New Delhi', 'Bangkok', 'Singapore', 'Riyadh',
  'Johannesburg', 'Mexico City', 'Toronto'
};

/// Exakte Koordinaten aller 180 Zeitzonen / Städte
const Map<String, (double, double)> _zonePoints = {
  // Europa
  'Europe/Berlin': (52.52, 13.40),
  'Europe/London': (51.51, -0.13),
  'Europe/Paris': (48.85, 2.35),
  'Europe/Tirane': (41.33, 19.82),
  'Europe/Andorra': (42.51, 1.52),
  'Europe/Vienna': (48.21, 16.37),
  'Europe/Brussels': (50.85, 4.35),
  'Europe/Athens': (37.98, 23.72),
  'Europe/Rome': (41.90, 12.49),
  'Europe/Madrid': (40.41, -3.70),
  'Europe/Stockholm': (59.33, 18.06),
  'Europe/Helsinki': (60.17, 24.94),
  'Europe/Zurich': (47.37, 8.54),
  'Europe/Amsterdam': (52.37, 4.89),
  'Europe/Lisbon': (38.72, -9.14),
  'Europe/Istanbul': (41.01, 28.97),
  'Europe/Kiev': (50.45, 30.52),
  'Europe/Minsk': (53.90, 27.57),
  'Europe/Sofia': (42.70, 23.32),
  'Europe/Zagreb': (45.81, 15.98),
  'Europe/Prague': (50.08, 14.44),
  'Europe/Copenhagen': (55.68, 12.57),
  'Europe/Tallinn': (59.44, 24.75),
  'Europe/Budapest': (47.50, 19.04),
  'Europe/Dublin': (53.35, -6.26),
  'Europe/Belgrade': (44.79, 20.47),
  'Europe/Riga': (56.95, 24.11),
  'Europe/Vaduz': (47.14, 9.52),
  'Europe/Vilnius': (54.69, 25.28),
  'Europe/Luxembourg': (49.61, 6.13),
  'Europe/Malta': (35.90, 14.51),
  'Europe/Chisinau': (47.01, 28.86),
  'Europe/Monaco': (43.73, 7.42),
  'Europe/Podgorica': (42.43, 19.26),
  'Europe/Skopje': (42.00, 21.43),
  'Europe/Bucharest': (44.43, 26.10),
  'Europe/Moscow': (55.75, 37.61),
  'Europe/San_Marino': (43.94, 12.46),
  'Europe/Warsaw': (52.23, 21.01),

  // Asien
  'Asia/Kabul': (34.55, 69.20),
  'Asia/Shanghai': (31.23, 121.47),
  'Asia/Kolkata': (22.57, 88.36),
  'Asia/Jakarta': (-6.20, 106.85),
  'Asia/Tokyo': (35.68, 139.76),
  'Asia/Seoul': (37.56, 126.97),
  'Asia/Ho_Chi_Minh': (21.03, 105.85),
  'Asia/Dubai': (25.20, 55.27),
  'Asia/Hong_Kong': (22.32, 114.17),
  'Asia/Yerevan': (40.18, 44.51),
  'Asia/Baku': (40.41, 49.87),
  'Asia/Bahrain': (26.23, 50.59),
  'Asia/Dhaka': (23.81, 90.41),
  'Asia/Thimphu': (27.47, 89.64),
  'Asia/Nicosia': (35.17, 33.37),
  'Asia/Tbilisi': (41.72, 44.79),
  'Asia/Baghdad': (33.31, 44.36),
  'Asia/Tehran': (35.69, 51.39),
  'Asia/Jerusalem': (31.77, 35.21),
  'Asia/Amman': (31.94, 35.93),
  'Asia/Almaty': (51.16, 71.47),
  'Asia/Kuwait': (29.37, 47.98),
  'Asia/Bishkek': (42.87, 74.59),
  'Asia/Vientiane': (17.97, 102.63),
  'Asia/Beirut': (33.89, 35.50),
  'Asia/Kuala_Lumpur': (3.14, 101.69),
  'Asia/Ulaanbaatar': (47.92, 106.92),
  'Asia/Yangon': (19.76, 96.08),
  'Asia/Kathmandu': (27.71, 85.32),
  'Asia/Pyongyang': (39.03, 125.76),
  'Asia/Muscat': (23.58, 58.41),
  'Asia/Karachi': (33.68, 73.04),
  'Asia/Hebron': (31.90, 35.20),
  'Asia/Qatar': (25.28, 51.53),
  'Asia/Riyadh': (24.71, 46.67),
  'Asia/Singapore': (1.35, 103.82),
  'Asia/Colombo': (6.92, 79.86),
  'Asia/Taipei': (25.03, 121.56),
  'Asia/Dushanbe': (38.56, 68.77),
  'Asia/Bangkok': (13.75, 100.50),
  'Asia/Dili': (-8.56, 125.57),
  'Asia/Ashgabat': (37.96, 58.38),
  'Asia/Tashkent': (41.30, 69.24),

  // Amerika
  'America/Argentina/Buenos_Aires': (-34.60, -58.38),
  'America/Sao_Paulo': (-15.79, -47.88),
  'America/Toronto': (45.42, -75.70),
  'America/Bogota': (4.71, -74.07),
  'America/Mexico_City': (19.43, -99.13),
  'America/New_York': (38.90, -77.03),
  'America/Caracas': (10.48, -66.90),
  'America/Los_Angeles': (34.05, -118.24),
  'America/Chicago': (41.88, -87.63),
  'America/Lima': (-12.04, -77.04),
  'America/Santiago': (-33.45, -70.66),
  'America/Costa_Rica': (9.93, -84.08),
  'America/Havana': (23.11, -82.37),
  'America/Dominica': (15.30, -61.39),
  'America/Santo_Domingo': (18.48, -69.93),
  'America/Guayaquil': (-0.18, -78.47),
  'America/El_Salvador': (13.69, -89.22),
  'America/Guatemala': (14.63, -90.51),
  'America/Guyana': (6.80, -58.16),
  'America/Port-au-Prince': (18.59, -72.31),
  'America/Tegucigalpa': (14.07, -87.21),
  'America/Jamaica': (17.97, -76.79),
  'America/Managua': (12.11, -86.24),
  'America/Panama': (8.98, -79.52),
  'America/Asuncion': (-25.26, -57.57),
  'America/St_Kitts': (17.30, -62.72),
  'America/St_Lucia': (14.01, -60.98),
  'America/St_Vincent': (13.16, -61.22),
  'America/Paramaribo': (5.85, -55.20),
  'America/Port_of_Spain': (10.65, -61.51),
  'America/Montevideo': (-34.90, -56.16),

  // Afrika
  'Africa/Algiers': (36.75, 3.06),
  'Africa/Cairo': (30.04, 31.23),
  'Africa/Harare': (-17.82, 31.05),
  'Africa/Luanda': (-8.83, 13.23),
  'Africa/Gaborone': (-24.65, 25.91),
  'Africa/Ouagadougou': (12.37, -1.52),
  'Africa/Bujumbura': (-3.38, 29.36),
  'Africa/Douala': (3.84, 11.50),
  'Africa/Bangui': (4.39, 18.55),
  'Africa/Ndjamena': (12.13, 15.05),
  'Africa/Kinshasa': (-4.44, 15.26),
  'Africa/Brazzaville': (-4.26, 15.28),
  'Africa/Djibouti': (11.82, 42.59),
  'Africa/Malabo': (3.75, 8.78),
  'Africa/Asmara': (15.32, 38.93),
  'Africa/Addis_Ababa': (9.03, 38.74),
  'Africa/Libreville': (0.41, 9.46),
  'Africa/Banjul': (13.45, -16.57),
  'Africa/Accra': (5.60, -0.18),
  'Africa/Conakry': (9.64, -13.57),
  'Africa/Bissau': (11.86, -15.60),
  'Africa/Nairobi': (-1.29, 36.82),
  'Africa/Maseru': (-29.31, 27.48),
  'Africa/Monrovia': (6.30, -10.80),
  'Africa/Tripoli': (32.88, 13.19),
  'Africa/Blantyre': (-13.96, 33.78),
  'Africa/Bamako': (12.63, -8.00),
  'Africa/Nouakchott': (18.07, -15.95),
  'Africa/Maputo': (-25.96, 32.57),
  'Africa/Windhoek': (-22.56, 17.06),
  'Africa/Niamey': (13.51, 2.12),
  'Africa/Lagos': (9.07, 7.39),
  'Africa/Kigali': (-1.94, 30.06),
  'Africa/Sao_Tome': (0.33, 6.73),
  'Africa/Dakar': (14.71, -17.46),
  'Africa/Freetown': (8.48, -13.23),
  'Africa/Mogadishu': (2.04, 45.31),
  'Africa/Johannesburg': (-25.74, 28.18),
  'Africa/Juba': (4.85, 31.58),
  'Africa/Khartoum': (15.50, 32.55),
  'Africa/Mbabane': (-26.30, 31.13),
  'Africa/Dar_es_Salaam': (-6.16, 35.74),
  'Africa/Lome': (6.13, 1.22),
  'Africa/Tunis': (36.80, 10.18),
  'Africa/Kampala': (0.34, 32.58),

  // Ozeanien & Inselstaaten
  'Australia/Sydney': (-35.28, 149.13),
  'Pacific/Auckland': (-41.28, 174.77),
  'Atlantic/Cape_Verde': (14.93, -23.51),
  'Indian/Comoro': (-11.71, 43.25),
  'Atlantic/Reykjavik': (64.14, -21.94),
  'Pacific/Tarawa': (1.32, 172.97),
  'Indian/Antananarivo': (-18.87, 47.50),
  'Indian/Maldives': (4.17, 73.50),
  'Pacific/Majuro': (7.10, 171.38),
  'Indian/Mauritius': (-20.16, 57.50),
  'Pacific/Nauru': (-0.52, 166.93),
  'Pacific/Palau': (7.50, 134.62),
  'Pacific/Port_Moresby': (-9.44, 147.18),
  'Pacific/Apia': (-13.83, -171.76),
  'Indian/Mahe': (-4.61, 55.45),
  'Pacific/Guadalcanal': (-9.44, 159.97),
  'Pacific/Tongatapu': (-21.13, -175.20),
  'Pacific/Funafuti': (-8.52, 179.19),
  'Pacific/Honolulu': (21.30, -157.85),
};

/// Kontur-Polygone für das Punkt-Raster
const List<List<List<double>>> _continents = [
  // Nordamerika
  [[71, -168], [71, -140], [60, -125], [48, -124], [34, -118], [23, -110], [16, -93], [8, -78], [12, -73], [25, -80], [30, -84], [35, -75], [44, -66], [52, -55], [60, -64], [70, -70], [82, -70], [82, -120]],
  // Grönland
  [[82, -50], [82, -18], [70, -20], [60, -42], [65, -53], [78, -72]],
  // Südamerika
  [[12, -72], [10, -62], [7, -50], [-2, -40], [-8, -35], [-20, -39], [-34, -53], [-54, -65], [-55, -71], [-45, -75], [-20, -70], [-5, -81], [9, -79]],
  // Europa & Skandinavien
  [[71, 28], [70, 20], [63, 10], [58, 6], [54, 9], [48, -4], [43, -9], [36, -5], [37, 15], [38, 24], [40, 29], [46, 14], [55, 21], [60, 30], [66, 23], [70, 31]],
  // Großbritannien & Irland
  [[58, -6], [58, -2], [52, 1], [50, -5], [54, -4]],
  [[55, -10], [55, -6], [51, -6], [51, -10]],
  // Island
  [[66, -24], [66, -13], [63, -13], [63, -24]],
  // Afrika
  [[37, -9], [37, 11], [32, 25], [30, 32], [22, 37], [12, 43], [10, 51], [0, 42], [-15, 40], [-34, 26], [-35, 18], [-22, 14], [-5, 12], [5, 2], [5, -10], [15, -17], [28, -13]],
  // Madagaskar
  [[-12, 49], [-16, 50], [-25, 47], [-25, 43], [-15, 46]],
  // Asien
  [[77, 104], [77, 170], [66, 170], [60, 162], [55, 135], [43, 131], [40, 120], [22, 114], [22, 108], [10, 104], [1, 104], [10, 98], [22, 88], [20, 73], [25, 62], [13, 44], [28, 34], [40, 27], [41, 38], [45, 50], [55, 60], [68, 74]],
  // Indien
  [[25, 68], [24, 88], [20, 86], [15, 80], [8, 77], [12, 75], [19, 72]],
  // Japan
  [[45, 142], [41, 140], [35, 136], [31, 130], [33, 130], [38, 138]],
  // Südostasien / Indonesien
  [[6, 117], [7, 108], [0, 109], [-6, 106], [-8, 115], [-8, 125], [1, 128], [5, 120]],
  [[18, 120], [18, 122], [10, 126], [6, 125], [10, 122]],
  // Australien & Neuseeland
  [[-11, 131], [-12, 142], [-24, 153], [-37, 150], [-38, 140], [-34, 115], [-22, 113], [-14, 126]],
  [[-34, 172], [-38, 178], [-41, 175], [-38, 174]],
  [[-41, 172], [-46, 170], [-46, 166], [-41, 171]],
];