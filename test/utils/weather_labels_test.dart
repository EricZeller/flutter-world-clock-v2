import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/models/weather.dart';
import 'package:world_clock_v2/utils/weather_labels.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final de = lookupAppLocalizations(const Locale('de'));

  test('the UV index names its risk level', () {
    expect([for (final index in [0, 3, 6, 8, 11]) uvIndexText(en, index)], [
      'UV 0 · low',
      'UV 3 · moderate',
      'UV 6 · high',
      'UV 8 · very high',
      'UV 11 · extreme',
    ]);
    expect([for (final index in [2, 5, 7, 10, 14]) uvIndexText(de, index)], [
      'UV 2 · niedrig',
      'UV 5 · mäßig',
      'UV 7 · hoch',
      'UV 10 · sehr hoch',
      'UV 14 · extrem',
    ]);
  });

  test('the moon phase is translated', () {
    expect([for (final phase in MoonPhase.values) moonPhaseText(de, phase)], [
      'Neumond',
      'Zunehmende Sichel',
      'Erstes Viertel',
      'Zunehmender Mond',
      'Vollmond',
      'Abnehmender Mond',
      'Letztes Viertel',
      'Abnehmende Sichel',
    ]);
    expect(moonPhaseText(en, MoonPhase.fullMoon, illumination: 98),
        'Full moon · 98%');
  });

  test('every language names every phase and risk level', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      final names = {
        for (final phase in MoonPhase.values) moonPhaseText(l10n, phase),
      };
      final risks = {
        for (final index in [0, 3, 6, 8, 11]) uvIndexText(l10n, index),
      };

      expect(names, hasLength(MoonPhase.values.length), reason: '$locale');
      expect(risks, hasLength(UvRisk.values.length), reason: '$locale');
    }
  });
}
