import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/models/weather.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:world_clock_v2/theme/app_theme.dart';
import 'package:world_clock_v2/utils/time_utils.dart';
import 'package:world_clock_v2/widgets/info_chip.dart';

Future<void> showForecastSheet(
  BuildContext context, {
  required City city,
  required WeatherReport report,
  required bool isOffline,
}) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) =>
        ForecastSheet(city: city, report: report, isOffline: isOffline),
  );
}

/// Current conditions, the next hours and the coming days for one city.
class ForecastSheet extends StatelessWidget {
  const ForecastSheet({
    super.key,
    required this.city,
    required this.report,
    required this.isOffline,
  });

  final City city;
  final WeatherReport report;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    final fahrenheit = settings.useFahrenheit;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final current = report.current;
    final today = report.today;
    final sunrise = today == null
        ? null
        : formatWttrTime(today.sunrise, use24hr: settings.use24hr);
    final sunset = today == null
        ? null
        : formatWttrTime(today.sunset, use24hr: settings.use24hr);
    final cityNow = wallClockIn(city.timeZone);
    final hours = report.upcomingHours(cityNow);
    final wind = fahrenheit
        ? '${current.windMph} mph'
        : '${current.windKmph} km/h';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            city.name,
            style: TextStyle(
              fontFamily: AppTheme.accentFontFamily,
              fontSize: 28,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(current.symbol, style: const TextStyle(fontSize: 48)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatTemperature(current.temperature(fahrenheit),
                          fahrenheit: fahrenheit),
                      style: textTheme.displaySmall
                          ?.copyWith(color: colorScheme.onSurface),
                    ),
                    Text(current.description, style: textTheme.titleMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                  Icons.thermostat_rounded,
                  null,
                  l10n.feelsLike(formatTemperature(
                      current.feelsLike(fahrenheit),
                      fahrenheit: fahrenheit))),
              _chip(Icons.water_drop_outlined, l10n.humidity,
                  '${current.humidity}%'),
              _chip(Icons.air_rounded, l10n.wind, wind),
              if (sunrise != null)
                _chip(Icons.wb_twilight_rounded, l10n.sunrise, sunrise),
              if (sunset != null)
                _chip(Icons.nights_stay_rounded, l10n.sunset, sunset),
            ],
          ),
          if (hours.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(l10n.nextHours, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: hours.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) =>
                    _HourTile(slot: hours[index], use24hr: settings.use24hr),
              ),
            ),
          ],
          if (report.days.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(l10n.forecast, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: colorScheme.primaryContainer,
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final day in report.days)
                    _DayTile(day: day, cityToday: cityNow),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                isOffline ? Icons.cloud_off_rounded : Icons.update_rounded,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.lastUpdated(formatUpdateTime(
                  report.fetchedAt,
                  use24hr: settings.use24hr,
                  locale: l10n.localeName,
                )),
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String? tooltip, String value) {
    final chip = InfoChip(icon: icon, label: value);
    if (tooltip == null) return chip;
    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      message: tooltip,
      child: chip,
    );
  }
}

class _HourTile extends StatelessWidget {
  const _HourTile({required this.slot, required this.use24hr});

  final HourlySlot slot;
  final bool use24hr;

  @override
  Widget build(BuildContext context) {
    final fahrenheit = context.watch<SettingsProvider>().useFahrenheit;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final forecast = slot.forecast;
    final time = (use24hr ? DateFormat('HH:mm') : DateFormat('h a'))
        .format(slot.time);

    return Tooltip(
      message: forecast.description,
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(time, style: textTheme.labelMedium),
            Text(forecast.symbol, style: const TextStyle(fontSize: 24)),
            Text('${forecast.temperature(fahrenheit)}°',
                style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600)),
            _RainChance(percent: forecast.chanceOfRain),
          ],
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day, required this.cityToday});

  final DailyForecast day;
  final DateTime cityToday;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fahrenheit = context.watch<SettingsProvider>().useFahrenheit;
    final colorScheme = Theme.of(context).colorScheme;
    final label = switch (calendarDaysBetween(cityToday, day.date)) {
      0 => l10n.today,
      1 => l10n.tomorrow,
      _ => DateFormat.EEEE(l10n.localeName).format(day.date),
    };
    final representative = day.representative;

    return ListTile(
      leading: Text(representative?.symbol ?? '✨',
          style: const TextStyle(fontSize: 28)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: representative == null
          ? null
          : Text(representative.description,
              maxLines: 1, overflow: TextOverflow.ellipsis),
      textColor: colorScheme.onPrimaryContainer,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${day.min(fahrenheit)}° / ${day.max(fahrenheit)}°',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          _RainChance(percent: day.chanceOfRain),
        ],
      ),
    );
  }
}

class _RainChance extends StatelessWidget {
  const _RainChance({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: '${AppLocalizations.of(context)!.chanceOfRain} $percent%',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.umbrella_rounded, size: 12, color: color),
          const SizedBox(width: 2),
          Text('$percent%',
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
