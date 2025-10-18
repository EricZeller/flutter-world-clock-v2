import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:world_clock_v2/data/data.dart';

void main() {
  group('Time Format Tests', () {
    setUp(() {
      tz.initializeTimeZones();
    });

    test('Global variables should have correct default values', () {
      expect(spThemeMode, equals("System"));
      expect(themeList, equals(["System", "Dark", "Light"]));
      expect(sp24hr, isTrue);
      expect(showSeconds, isTrue);
      expect(showSecondsLocal, isFalse);
      expect(spMoreInfo, isTrue);
      expect(wttrServer, equals("https://wttr.in"));
      expect(useFahrenheit, isFalse);
      expect(useCustomColor, isFalse);
      expect(colorIndex, equals(4));
    });

    test('Timezone conversion should work correctly', () {
      final berlinLocation = tz.getLocation('Europe/Berlin');
      final tokyoLocation = tz.getLocation('Asia/Tokyo');
      final newYorkLocation = tz.getLocation('America/New_York');

      final now = tz.TZDateTime.now(berlinLocation);
      final tokyoTime = tz.TZDateTime.now(tokyoLocation);
      final newYorkTime = tz.TZDateTime.now(newYorkLocation);

      // Verify that the times are different
      expect(now.hour, isNot(equals(tokyoTime.hour)));
      expect(now.hour, isNot(equals(newYorkTime.hour)));
    });
  });
}