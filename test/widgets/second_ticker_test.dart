import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_clock_v2/widgets/second_ticker.dart';

void main() {
  testWidgets('rebuilds once per second until disposed', (tester) async {
    var builds = 0;
    await tester.pumpWidget(SecondTicker(builder: (_) {
      builds++;
      return const SizedBox();
    }));
    expect(builds, 1);

    for (var second = 0; second < 3; second++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(builds, 4);

    await tester.pumpWidget(const SizedBox());
    for (var second = 0; second < 3; second++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(builds, 4);
  });
}
