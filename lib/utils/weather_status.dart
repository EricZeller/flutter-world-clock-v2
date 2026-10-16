import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/services/weather_service.dart';

/// Text shown instead of the weather while there is no report.
String weatherStatusText(
  AppLocalizations l10n, {
  required WeatherFailure? failure,
  required bool isLoading,
}) {
  if (isLoading) return l10n.weatherLoading;
  if (failure == WeatherFailure.server) return l10n.apiError;
  return l10n.connectionError;
}
