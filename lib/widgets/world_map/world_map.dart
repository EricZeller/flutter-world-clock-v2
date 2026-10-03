import 'dart:async';

import 'package:flutter/material.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/widgets/world_map/map_geometry.dart';
import 'package:world_clock_v2/widgets/world_map/world_map_painter.dart';

/// Dot matrix world map with day and night shading. The map keeps its
/// proportions, covers the available space and can be panned and zoomed;
/// it opens centered on the selected city.
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
  /// How close (in logical pixels on screen) a tap must be to a marker.
  static const tapRadius = 24.0;

  final _controller = TransformationController();
  double _scale = 1.0;
  Size? _viewport;
  late LatLng _sun;
  late final Timer _sunTimer;

  @override
  void initState() {
    super.initState();
    _sun = subsolarPoint(DateTime.now());
    // The day/night boundary moves a quarter degree per minute.
    _sunTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() => _sun = subsolarPoint(DateTime.now()));
    });
    _controller.addListener(() {
      final scale = _controller.value.getMaxScaleOnAxis();
      if ((scale - _scale).abs() > .05) setState(() => _scale = scale);
    });
  }

  @override
  void dispose() {
    _sunTimer.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// The smallest map size that still covers the whole [viewport].
  static Size mapSizeFor(Size viewport) {
    final height = viewport.height > viewport.width / mapAspectRatio
        ? viewport.height
        : viewport.width / mapAspectRatio;
    return Size(height * mapAspectRatio, height);
  }

  void _centerOnSelectedCity(Size viewport, Size mapSize) {
    final point =
        MapProjection(mapSize).project(cityPosition(widget.selectedCity));
    final dx = (viewport.width / 2 - point.dx)
        .clamp(viewport.width - mapSize.width, 0.0);
    final dy = (viewport.height / 2 - point.dy)
        .clamp(viewport.height - mapSize.height, 0.0);
    _controller.value = Matrix4.translationValues(dx, dy, 0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.biggest;
        final mapSize = mapSizeFor(viewport);
        if (viewport != _viewport) {
          final isFirstLayout = _viewport == null;
          _viewport = viewport;
          if (isFirstLayout) {
            // Nothing listens to the controller yet, so it can be set now.
            _centerOnSelectedCity(viewport, mapSize);
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _centerOnSelectedCity(viewport, mapSize);
            });
          }
        }

        return InteractiveViewer(
          transformationController: _controller,
          constrained: false,
          minScale: 1.0,
          maxScale: 8.0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final city = nearestCity(details.localPosition, mapSize);
              if (city != null) widget.onCityTap(city);
            },
            child: SizedBox.fromSize(
              size: mapSize,
              child: Stack(
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      size: mapSize,
                      painter: LandPainter(
                        sun: _sun,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  CustomPaint(
                    size: mapSize,
                    painter: MarkerPainter(
                      cities: widget.cities,
                      selectedCity: widget.selectedCity,
                      sun: _sun,
                      scale: _scale,
                      markerColor: colorScheme.secondary,
                      sunColor: colorScheme.tertiary,
                      labelBackground: colorScheme.inverseSurface,
                      labelColor: colorScheme.onInverseSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// The drawn marker closest to [position] within [tapRadius], if any.
  @visibleForTesting
  City? nearestCity(Offset position, Size mapSize) {
    final projection = MapProjection(mapSize);
    City? nearest;
    var distance = tapRadius / _scale;
    for (final city in widget.cities) {
      final current =
          (projection.project(cityPosition(city)) - position).distance;
      if (current < distance) {
        distance = current;
        nearest = city;
      }
    }
    return nearest;
  }
}
