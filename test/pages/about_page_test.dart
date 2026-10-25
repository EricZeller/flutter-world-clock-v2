import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock_v2/pages/about.dart';

import '../helpers/test_app.dart';

void main() {
  group('parseAppVersion', () {
    test('strips the build number', () {
      expect(parseAppVersion('name: app\nversion: 1.10.0+31\n'), '1.10.0');
    });

    test('accepts a version without build number', () {
      expect(parseAppVersion('version: 2.0.1\n'), '2.0.1');
    });

    test('accepts quoted versions and trailing comments', () {
      expect(parseAppVersion('version: "1.2.3+4" # release\n'), '1.2.3');
      expect(parseAppVersion("version: '1.2.3'\n"), '1.2.3');
    });

    test('accepts Windows line endings and extra spaces', () {
      expect(parseAppVersion('name: app\r\nversion:   1.10.0+31  \r\n'), '1.10.0');
    });

    test('ignores nested version keys', () {
      const pubspec = 'dependencies:\n  foo:\n    version: 9.9.9\nversion: 1.0.0+1\n';
      expect(parseAppVersion(pubspec), '1.0.0');
    });

    test('throws when there is no version entry', () {
      expect(() => parseAppVersion('name: app\n'), throwsFormatException);
    });

    test('reads the version of the real pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final line = pubspec
          .split('\n')
          .firstWhere((line) => line.startsWith('version:'));
      final expected = line.substring('version:'.length).trim().split('+').first;
      expect(parseAppVersion(pubspec), expected);
    });
  });

  testWidgets('credits the data sources with their licenses', (tester) async {
    SharedPreferences.setMockInitialValues({});
    // The page reads pubspec.yaml for the version, which needs real I/O.
    await tester.runAsync(
      () async =>
          pumpPage(tester, const AboutPage(), settings: await loadSettings()),
    );

    expect(find.text('Data sources', skipOffstage: false), findsOneWidget);
    for (final source in [
      'GeoNames',
      'Unicode CLDR',
      'IANA Time Zone Database',
      'flagpedia.net',
      'wttr.in',
      'Google Fonts',
    ]) {
      expect(find.text(source, skipOffstage: false), findsOneWidget);
    }
    expect(find.textContaining('CC BY 4.0', skipOffstage: false),
        findsOneWidget,
        reason: 'the license of GeoNames');
    expect(find.textContaining('SIL Open Font License', skipOffstage: false),
        findsOneWidget);
    expect(find.byIcon(Icons.open_in_new, skipOffstage: false),
        findsNWidgets(6));
  });
}
