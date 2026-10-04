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
  const LocalTimeSection({super.key, required this.city});

  final City city;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    return SecondTicker(builder: (context) {
      final localTime = clockFormat(
        use24hr: settings.use24hr,
        showSeconds: settings.showSecondsLocal,
      ).format(DateTime.now());

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
                label: formatOffset(differenceToLocal(city.timeZone)),
              ),
            ),
          ],
        ],
      );
    });
  }
}
