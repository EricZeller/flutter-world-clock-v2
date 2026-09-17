import 'package:flutter/material.dart';
import 'package:world_clock_v2/pages/location.dart';

class WorldMap extends StatefulWidget {
  const WorldMap({super.key, required this.cities, required this.selectedCity, required this.onCityTap});

  final List<City> cities;
  final City selectedCity;
  final ValueChanged<City> onCityTap;

  @override
  State<WorldMap> createState() => _WorldMapState();
}

class _WorldMapState extends State<WorldMap> {
  final _controller = TransformationController();
  double _scale = 1;

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
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return InteractiveViewer(
          transformationController: _controller,
          minScale: 1,
          maxScale: 2.5,
          boundaryMargin: const EdgeInsets.all(80),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final city = _nearestCity(details.localPosition, size);
                if (city != null) widget.onCityTap(city);
              },
              child: CustomPaint(
              painter: _WorldMapPainter(
                cities: widget.cities,
                selectedCity: widget.selectedCity,
                showLabels: _scale >= 1.7,
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
    var distance = 28.0;
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

class _WorldMapPainter extends CustomPainter {
  _WorldMapPainter({required this.cities, required this.selectedCity, required this.showLabels, required this.color, required this.markerColor, required this.labelBackground, required this.labelColor});

  final List<City> cities;
  final City selectedCity;
  final bool showLabels;
  final Color color;
  final Color markerColor;
  final Color labelBackground;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final land = Paint()
      ..color = color.withValues(alpha: .16)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = color.withValues(alpha: .5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Deliberately coarse continent silhouettes: no map tiles or image assets.
    for (final polygon in _continents) {
      final path = Path();
      for (var i = 0; i < polygon.length; i++) {
        final point = _projectLatLon(polygon[i][0], polygon[i][1], size);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, land);
      canvas.drawPath(path, outline);
    }

    for (final city in cities) {
      final point = _project(city, size);
      canvas.drawCircle(point, city.isCustom ? 9 : 5, Paint()..color = markerColor);
      if (showLabels || city == selectedCity) {
        canvas.drawCircle(point, city.isCustom ? 16 : 11,
            Paint()..color = markerColor.withValues(alpha: .35));
        final label = TextPainter(
          text: TextSpan(
            text: city.name,
            style: TextStyle(
              color: labelColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: size.width * .35);
        final bubble = RRect.fromRectAndRadius(
          Rect.fromLTWH(point.dx + 8, point.dy - 26, label.width + 12, label.height + 8),
          const Radius.circular(8),
        );
        canvas.drawRRect(bubble, Paint()..color = labelBackground.withValues(alpha: .98));
        label.paint(canvas, point + const Offset(14, -22));
      }
      if (city.isCustom) {
        canvas.drawCircle(point, 14, Paint()..color = markerColor.withValues(alpha: .22));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WorldMapPainter oldDelegate) =>
      oldDelegate.cities != cities || oldDelegate.selectedCity != selectedCity || oldDelegate.showLabels != showLabels || oldDelegate.color != color || oldDelegate.labelBackground != labelBackground;
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

const Map<String, (double, double)> _zonePoints = {
  'Europe/Berlin': (52.5, 13.4), 'Europe/London': (51.5, -0.1),
  'Europe/Paris': (48.9, 2.3), 'Europe/Moscow': (55.8, 37.6),
  'America/New_York': (40.7, -74), 'America/Chicago': (41.9, -87.6),
  'America/Denver': (39.7, -104.9), 'America/Los_Angeles': (34.1, -118.2),
  'America/Sao_Paulo': (-23.5, -46.6), 'America/Argentina/Buenos_Aires': (-34.6, -58.4),
  'Asia/Kolkata': (28.6, 77.2), 'Asia/Shanghai': (31.2, 121.5),
  'Asia/Tokyo': (35.7, 139.7), 'Asia/Seoul': (37.6, 127),
  'Asia/Singapore': (1.3, 103.8), 'Asia/Dubai': (25.2, 55.3),
  'Asia/Kabul': (34.5, 69.2), 'Africa/Cairo': (30, 31.2),
  'Africa/Johannesburg': (-26.2, 28), 'Australia/Sydney': (-33.9, 151.2),
  'Pacific/Auckland': (-36.9, 174.8),
};

const List<List<List<double>>> _continents = [
  // North America, Greenland and Central America.
  [[72, -168], [72, -100], [83, -45], [65, -20], [58, -55], [50, -55], [25, -80], [8, -77], [15, -95], [30, -105], [50, -125]],
  [[12, -82], [20, -87], [25, -80], [10, -60], [8, -78]],
  // South America.
  [[12, -72], [5, -52], [-5, -35], [-22, -40], [-55, -68], [-50, -75], [-5, -80]],
  // Europe.
  [[71, -10], [70, 10], [65, 25], [55, 40], [42, 40], [35, 30], [36, 10], [43, -10], [55, -10]],
  // Africa.
  [[36, -17], [37, 10], [35, 33], [5, 42], [-35, 32], [-35, 15], [-5, -5], [10, -17]],
  // Asia, India and Southeast Asia.
  [[75, 40], [72, 180], [55, 170], [35, 145], [5, 140], [5, 105], [20, 95], [25, 75], [35, 45]],
  [[35, 75], [30, 80], [8, 77], [5, 95], [25, 100], [30, 90]],
  // Australia and Japan.
  [[-10, 110], [-10, 155], [-25, 170], [-45, 170], [-40, 115]],
  [[45, 140], [35, 145], [30, 135], [35, 130]],
];
