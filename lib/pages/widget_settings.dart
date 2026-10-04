import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:world_clock_v2/services/home_widget_service.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class WidgetSettingsPage extends StatelessWidget {
  const WidgetSettingsPage({super.key});

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
                  _WidgetMockup(
                    opacity: settings.widgetOpacity,
                    layout: settings.widgetLayout,
                    use24hr: settings.use24hr,
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
                    onChanged: (value) {
                      settings.setWidgetOpacity(value);
                      HomeWidgetService.updateAppearance(
                        opacity: value,
                        layout: settings.widgetLayout,
                      );
                    },
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
  final double opacity;
  final String layout;
  final bool use24hr;

  const _WidgetMockup({
    required this.opacity,
    required this.layout,
    required this.use24hr,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = AppLocalizations.of(context)!.localeName;
    final now = DateTime.now();
    // Same formats as the home screen widget.
    final timeStr = DateFormat(use24hr ? 'HH:mm' : 'hh:mm a').format(now);
    final dateStr = DateFormat('EEE, d. MMM', locale).format(now);

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
                    Text(
                      "Berlin",
                      style: TextStyle(
                        fontFamily: 'Pacifico',
                        fontSize: 28,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
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
                    child: Text(
                      "Berlin",
                      style: TextStyle(
                        fontFamily: 'Pacifico',
                        fontSize: 20,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
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
