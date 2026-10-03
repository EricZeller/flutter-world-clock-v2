import 'package:flutter/material.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/widgets/world_map/world_map_painter.dart';

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
                painter: DotMatrixWorldMapPainter(
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
      final point = projectCity(city, size);
      final current = (point - position).distance;
      if (current < distance) {
        distance = current;
        nearest = city;
      }
    }
    return nearest;
  }
}
