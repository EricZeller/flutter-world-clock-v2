import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/services/city_repository.dart';
import 'package:world_clock_v2/services/home_widget_service.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:world_clock_v2/utils/time_utils.dart';
import 'package:world_clock_v2/widgets/second_ticker.dart';

class WidgetSettingsPage extends StatefulWidget {
  const WidgetSettingsPage({super.key});

  @override
  State<WidgetSettingsPage> createState() => _WidgetSettingsPageState();
}

class _WidgetSettingsPageState extends State<WidgetSettingsPage> {
  // The preview shows the same city as the home screen widget.
  City _city = City.berlin;

  @override
  void initState() {
    super.initState();
    context.read<CityRepository>().loadSelectedCity().then((city) {
      if (mounted && city != null) setState(() => _city = city);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.widgetSettings),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                          Colors.blueGrey.shade900,
                          Colors.blueGrey.shade700,
                        ]
                      : [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        ],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.widgetPreview,
                    style: TextStyle(
                      // White only works on the dark gradient.
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // The Actual Widget Mockup
                  SecondTicker(
                    builder: (context) => _WidgetMockup(
                      city: _city,
                      opacity: settings.widgetOpacity,
                      layout: settings.widgetLayout,
                      use24hr: settings.use24hr,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transparency Slider
                  Text(
                    l10n.widgetTransparency,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    value: settings.widgetOpacity,
                    min: 0.1,
                    max: 1.0,
                    onChanged: settings.setWidgetOpacity,
                    // Redrawing the home screen widget is expensive, so it
                    // is only updated once the slider is released.
                    onChangeEnd: (value) => HomeWidgetService.updateAppearance(
                      opacity: value,
                      layout: settings.widgetLayout,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Layout Selection
                  Text(
                    l10n.widgetLayout,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'detailed',
                        label: Text(l10n.layoutDetailed),
                        icon: const Icon(Icons.view_quilt),
                      ),
                      ButtonSegment(
                        value: 'compact',
                        label: Text(l10n.layoutCompact),
                        icon: const Icon(Icons.view_stream),
                      ),
                    ],
                    selected: {settings.widgetLayout},
                    onSelectionChanged: (newSelection) {
                      final layout = newSelection.first;
                      settings.setWidgetLayout(layout);
                      HomeWidgetService.updateAppearance(
                        opacity: settings.widgetOpacity,
                        layout: layout,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WidgetMockup extends StatelessWidget {
  final City city;
  final double opacity;
  final String layout;
  final bool use24hr;

  const _WidgetMockup({
    required this.city,
    required this.opacity,
    required this.layout,
    required this.use24hr,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = AppLocalizations.of(context)!.localeName;
    // Time and date of the city, with the same patterns as the home screen
    // widget. The date follows the app language.
    final now = wallClockIn(city.timeZone);
    final timeStr = clockFormat(use24hr: use24hr, showSeconds: false).format(now);
    final dateStr = DateFormat('EEE, d. MMM', locale).format(now);
    // The widget draws the city name in the primary color.
    final cityStyle = TextStyle(fontFamily: 'Pacifico', color: colorScheme.primary);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(24),
      ),
      child: layout == 'detailed'
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(city.name,
                            style: cityStyle.copyWith(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '☀️ 18°',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Shrinks like the real widget, e.g. for "10:57 AM".
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          timeStr,
                          style: TextStyle(
                            fontFamily: 'Red Hat Display',
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        dateStr,
                        style: TextStyle(
                          fontFamily: 'Red Hat Display',
                          fontSize: 14,
                          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(city.name,
                        style: cityStyle.copyWith(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontFamily: 'Red Hat Display',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
    );
  }
}
