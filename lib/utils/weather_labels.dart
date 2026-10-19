import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/models/weather.dart';

/// UV index with its WHO risk level, e.g. `UV 6 · high`.
String uvIndexText(AppLocalizations l10n, int uvIndex) {
  final risk = switch (UvRisk.of(uvIndex)) {
    UvRisk.low => l10n.uvRiskLow,
    UvRisk.moderate => l10n.uvRiskModerate,
    UvRisk.high => l10n.uvRiskHigh,
    UvRisk.veryHigh => l10n.uvRiskVeryHigh,
    UvRisk.extreme => l10n.uvRiskExtreme,
  };
  return l10n.uvIndexValue('$uvIndex', risk);
}

/// Moon phase with its illumination, e.g. `Full moon · 98%`.
String moonPhaseText(AppLocalizations l10n, MoonPhase phase,
    {int? illumination}) {
  final name = switch (phase) {
    MoonPhase.newMoon => l10n.moonNew,
    MoonPhase.waxingCrescent => l10n.moonWaxingCrescent,
    MoonPhase.firstQuarter => l10n.moonFirstQuarter,
    MoonPhase.waxingGibbous => l10n.moonWaxingGibbous,
    MoonPhase.fullMoon => l10n.moonFull,
    MoonPhase.waningGibbous => l10n.moonWaningGibbous,
    MoonPhase.lastQuarter => l10n.moonLastQuarter,
    MoonPhase.waningCrescent => l10n.moonWaningCrescent,
  };
  return illumination == null ? name : '$name · $illumination%';
}
