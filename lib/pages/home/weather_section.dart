import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/models/weather.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:world_clock_v2/services/weather_service.dart';
import 'package:world_clock_v2/utils/time_utils.dart';
import 'package:world_clock_v2/widgets/info_chip.dart';

/// Weather summary on the home screen. Tapping it opens the forecast.
class WeatherSection extends StatelessWidget {
  const WeatherSection({
    super.key,
    required this.report,
    required this.failure,
    required this.isLoading,
    required this.onTap,
  });

  final WeatherReport? report;
  final WeatherFailure? failure;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.onPrimaryContainer;
    final report = this.report;

    final String text;
    if (report != null) {
      text = report.summary(fahrenheit: settings.useFahrenheit);
    } else if (isLoading) {
      text = l10n.weatherLoading;
    } else if (failure == WeatherFailure.server) {
      text = l10n.apiError;
    } else {
      text = l10n.connectionError;
    }

    final sunrise = report?.today == null
        ? null
        : formatWttrTime(report!.today!.sunrise, use24hr: settings.use24hr);
    final sunset = report?.today == null
        ? null
        : formatWttrTime(report!.today!.sunset, use24hr: settings.use24hr);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Semantics(
            button: report != null,
            onTapHint: l10n.showForecast,
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: report == null
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      onTap();
                    },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(text, style: TextStyle(fontSize: 20.0, color: color)),
                      if (report != null) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.expand_more_rounded,
                          color: colorScheme.primary,
                          semanticLabel: l10n.showForecast,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (report != null && failure != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 14, color: color.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Text(
                l10n.lastUpdated(formatUpdateTime(
                  report.fetchedAt,
                  use24hr: settings.use24hr,
                  locale: l10n.localeName,
                )),
                style: TextStyle(
                    fontSize: 13, color: color.withValues(alpha: 0.7)),
              ),
            ],
          ),
        if (settings.showMoreInfo && (sunrise != null || sunset != null))
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              spacing: 8,
              children: [
                if (sunrise != null)
                  Tooltip(
                    triggerMode: TooltipTriggerMode.tap,
                    message: l10n.sunrise,
                    child: InfoChip(
                        icon: Icons.wb_twilight_rounded, label: sunrise),
                  ),
                if (sunset != null)
                  Tooltip(
                    triggerMode: TooltipTriggerMode.tap,
                    message: l10n.sunset,
                    child: InfoChip(
                        icon: Icons.nights_stay_rounded, label: sunset),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
