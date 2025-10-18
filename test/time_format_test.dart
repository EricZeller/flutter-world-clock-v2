import 'package:flutter_test/flutter_test.dart';
import 'package:world_clock_v2/main.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:world_clock_v2/services/settings_provider.dart';

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('Time Formatting Tests', () {
    late MyHomePage homePage;

    setUp(() {
      homePage = const MyHomePage(title: 'Test');
    });

    test('Time format should respect 24-hour setting', () {
      final state = _MyHomePageState();
      
      // Test 24-hour format
      sp24hr = true;
      showSeconds = false;
      final time24 = state.getTimeInTimeZone('Europe/Berlin');
      expect(time24.contains('AM'), false);
      expect(time24.contains('PM'), false);

      // Test 12-hour format
      sp24hr = false;
      final time12 = state.getTimeInTimeZone('Europe/Berlin');
      expect(time12.contains('AM') || time12.contains('PM'), true);
    });

    test('Seconds should be shown when enabled', () {
      final state = _MyHomePageState();
      
      // Test with seconds
      sp24hr = true;
      showSeconds = true;
      final timeWithSeconds = state.getTimeInTimeZone('Europe/Berlin');
      expect(timeWithSeconds.split(':').length, 3);

      // Test without seconds
      showSeconds = false;
      final timeWithoutSeconds = state.getTimeInTimeZone('Europe/Berlin');
      expect(timeWithoutSeconds.split(':').length, 2);
    });

    test('Local time format should be correct', () {
      final state = _MyHomePageState();
      
      sp24hr = true;
      showSecondsLocal = false;
      final localTime = state.getLocalTime();
      expect(localTime.startsWith('Local time: '), true);
      expect(localTime.contains('AM'), false);
      expect(localTime.contains('PM'), false);
    });
  });
}