import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/widgets/world_map/map_geometry.dart';
import 'package:world_clock_v2/widgets/world_map/world_map.dart';
import 'package:world_clock_v2/widgets/world_map/world_map_painter.dart';

import '../helpers/test_app.dart';

const funafuti = City(
  name: 'Funafuti',
  country: 'Tuvalu',
  timeZone: 'Pacific/Funafuti',
  flag: '',
  utc: '+12:00',
  weatherZone: 'Funafuti',
);

void main() {
  const viewport = Size(400, 800);
  final cities = [City.berlin, tokyo, funafuti];

  Future<List<City>> pumpMap(WidgetTester tester, City selected) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final tapped = <City>[];
    await tester.pumpWidget(MaterialApp(
      home: WorldMap(
        cities: cities,
        selectedCity: selected,
        onCityTap: tapped.add,
      ),
    ));
    return tapped;
  }

  Matrix4 transform(WidgetTester tester) => tester
      .widget<InteractiveViewer>(find.byType(InteractiveViewer))
      .transformationController!
      .value;

  testWidgets('keeps proportions and covers the screen', (tester) async {
    await pumpMap(tester, City.berlin);

    final mapSize = tester.getSize(_land);
    expect(mapSize.height, viewport.height);
    expect(mapSize.width, viewport.height * mapAspectRatio);
  });

  testWidgets('opens centered on the selected city', (tester) async {
    await pumpMap(tester, tokyo);

    final mapSize = Size(viewport.height * mapAspectRatio, viewport.height);
    final tokyoOnMap = MapProjection(mapSize).project(cityPosition(tokyo));
    final onScreen = MatrixUtils.transformPoint(transform(tester), tokyoOnMap);
    expect(onScreen.dx, closeTo(viewport.width / 2, 0.01));
  });

  testWidgets('does not scroll past the edge of the map', (tester) async {
    await pumpMap(tester, funafuti);

    final mapWidth = viewport.height * mapAspectRatio;
    expect(transform(tester).getTranslation().x,
        closeTo(viewport.width - mapWidth, 0.01));
  });

  testWidgets('tapping a marker selects its city', (tester) async {
    final tapped = await pumpMap(tester, tokyo);

    await tester.tapAt(Offset(viewport.width / 2, 0) +
        Offset(0, _screenY(tester, tokyo)));

    expect(tapped, [tokyo]);
  });

  testWidgets('tapping next to all markers selects nothing', (tester) async {
    final tapped = await pumpMap(tester, tokyo);

    await tester.tapAt(Offset(viewport.width / 2 + 60, _screenY(tester, tokyo)));

    expect(tapped, isEmpty);
  });
}

final _land = find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.painter is LandPainter);

double _screenY(WidgetTester tester, City city) {
  final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
  final mapSize = tester.getSize(_land);
  final point = MapProjection(mapSize).project(cityPosition(city));
  return MatrixUtils.transformPoint(
          viewer.transformationController!.value, point)
      .dy;
}
