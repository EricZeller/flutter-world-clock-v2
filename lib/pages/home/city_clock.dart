import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:world_clock_v2/theme/app_theme.dart';
import 'package:world_clock_v2/utils/time_utils.dart';

/// City name, optional country/UTC line and the large clock.
class CityClock extends StatelessWidget {
  const CityClock({super.key, required this.city});

  final City city;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final color = Theme.of(context).colorScheme.onPrimaryContainer;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              city.name,
              style: TextStyle(
                fontSize: 55.0,
                fontFamily: AppTheme.accentFontFamily,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10.0),
        if (settings.showMoreInfo) ...[
          const SizedBox(height: 20.0),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "${city.country.isEmpty ? '' : '${city.country}, '}UTC${city.utc}",
              style: TextStyle(letterSpacing: 2, fontSize: 18, color: color),
            ),
          ),
        ],
        SizedBox(
          height: 120,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatTimeInZone(
                city.timeZone,
                use24hr: settings.use24hr,
                showSeconds: settings.showSeconds,
              ),
              style: TextStyle(fontSize: 80.0, color: color),
            ),
          ),
        ),
      ],
    );
  }
}
