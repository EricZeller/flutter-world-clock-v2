import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_clock_v2/widgets/info_chip.dart';

void main() {
  testWidgets('a long label wraps instead of overflowing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Center(
            child: SizedBox(
              width: 280,
              child: Wrap(
                children: [
                  InfoChip(symbol: '🌖', label: 'Gibbeuse décroissante · 98%'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(InfoChip)).width,
        lessThanOrEqualTo(280));
  });
}
