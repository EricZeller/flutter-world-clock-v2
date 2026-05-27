import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
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
                  colors: [
                    Colors.blueGrey.shade900,
                    Colors.blueGrey.shade700,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.widgetPreview,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  // The Actual Widget Mockup
                  _WidgetMockup(
                    opacity: settings.widgetOpacity,
                    layout: settings.widgetLayout,
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
                      _updateAndroidWidgetSettings(
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
                      _updateAndroidWidgetSettings(
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

  Future<void> _updateAndroidWidgetSettings({
    required double opacity,
    required String layout,
  }) async {
    await HomeWidget.saveWidgetData<String>('widgetOpacity', opacity.toString());
    await HomeWidget.saveWidgetData<String>('widgetLayout', layout);
    await HomeWidget.updateWidget(
      name: 'WorldClockWidgetProvider',
      androidName: 'WorldClockWidgetProvider',
    );
  }
}

class _WidgetMockup extends StatelessWidget {
  final double opacity;
  final String layout;

  const _WidgetMockup({required this.opacity, required this.layout});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);
    final dateStr = DateFormat('EEE, d. MMM').format(now);

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
                        fontSize: 18,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Icon(Icons.wb_sunny, color: colorScheme.onPrimaryContainer, size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontFamily: 'Red Hat Display',
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
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
                Text(
                  "Berlin",
                  style: TextStyle(
                    fontFamily: 'Pacifico',
                    fontSize: 20,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
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
