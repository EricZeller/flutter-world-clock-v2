import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:world_clock_v2/utils/time_utils.dart';
import 'package:world_clock_v2/widgets/info_chip.dart';
import 'package:world_clock_v2/widgets/second_ticker.dart';

/// Local device time and the difference to the selected city.
class LocalTimeSection extends StatelessWidget {
  const LocalTimeSection({
    super.key,
    required this.city,
    this.clock = DateTime.now,
  });

  final City city;
  final DateTime Function() clock;

  /// E.g. "Clocks change in 3 days: +01:00", or `null` without a change in
  /// the next two weeks.
  String? _offsetChangeText(AppLocalizations l10n, DateTime now) {
    final next = nextOffsetChange(city.timeZone, now: now);
    if (next == null) return null;
    final change = formatOffset(next.change);
    final days = calendarDaysBetween(
      wallClockIn(city.timeZone, now: now),
      wallClockIn(city.timeZone, now: next.at),
    );
    return switch (days) {
      0 => l10n.offsetChangeToday(change),
      1 => l10n.offsetChangeTomorrow(change),
      _ => l10n.offsetChangeInDays(days, change),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    return SecondTicker(builder: (context) {
      final localTime = clockFormat(
        use24hr: settings.use24hr,
        showSeconds: settings.showSecondsLocal,
      ).format(clock());
      final offsetChange = _offsetChangeText(l10n, clock());

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.localTime(localTime),
            style: TextStyle(
              fontSize: 30.0,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (settings.showMoreInfo) ...[
            const SizedBox(height: 6),
            Tooltip(
              triggerMode: TooltipTriggerMode.tap,
              message: l10n.timeDifferenceTooltip,
              child: InfoChip(
                icon: Icons.schedule_rounded,
                label: formatOffset(
                    differenceToLocal(city.timeZone, now: clock())),
              ),
            ),
            if (offsetChange != null) ...[
              const SizedBox(height: 6),
              Tooltip(
                triggerMode: TooltipTriggerMode.tap,
                message: l10n.offsetChangeTooltip,
                child: InfoChip(
                  icon: Icons.more_time_rounded,
                  label: offsetChange,
                ),
              ),
            ],
          ],
        ],
      );
    });
  }
}
