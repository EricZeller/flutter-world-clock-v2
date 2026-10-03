import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/pages/settings/color_picker_tile.dart';
import 'package:world_clock_v2/pages/settings/settings_widgets.dart';
import 'package:world_clock_v2/pages/settings/wttr_server_tile.dart';
import 'package:world_clock_v2/services/home_widget_service.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:world_clock_v2/theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _urlController;
  bool _isValidUrl = true;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: context.read<SettingsProvider>().wttrServer,
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedServer => _isUnsaved(context.read<SettingsProvider>());

  bool _isUnsaved(SettingsProvider settings) =>
      settings.wttrServer != _urlController.text;

  void _saveUrl(AppLocalizations l10n) {
    if (!_hasUnsavedServer) {
      showInfoDialog(context, l10n.noChanges, '');
      return;
    }
    final enteredUrl = _urlController.text;
    if (WttrServerTile.isValidUrl(enteredUrl)) {
      context.read<SettingsProvider>().setWttrServer(enteredUrl);
      showInfoDialog(context, l10n.urlSaved, l10n.serverSuccessNotice);
    } else {
      setState(() => _isValidUrl = false);
    }
  }

  void _resetUrl(AppLocalizations l10n) {
    setState(() {
      _urlController.text = SettingsProvider.defaultWttrServer;
      _isValidUrl = true;
    });
    context
        .read<SettingsProvider>()
        .setWttrServer(SettingsProvider.defaultWttrServer);
    showInfoDialog(context, l10n.urlRestored, l10n.apiUpdateNotice);
  }

  void _close(AppLocalizations l10n) {
    HapticFeedback.lightImpact();
    if (_hasUnsavedServer) {
      showInfoDialog(context, l10n.unsavedChanges, l10n.saveChangesPrompt);
    } else {
      Navigator.pop(context);
    }
  }

  String _themeModeLabel(AppLocalizations l10n, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => l10n.themeSystem,
      ThemeMode.dark => l10n.themeDark,
      ThemeMode.light => l10n.themeLight,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_isUnsaved(settings),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(l10n);
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainer,
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            l10n.settings,
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontFamily: AppTheme.accentFontFamily,
              fontSize: 24,
            ),
          ),
          backgroundColor: colorScheme.primaryContainer,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: colorScheme.onPrimaryContainer,
              semanticLabel: l10n.ok,
            ),
            onPressed: () => _close(l10n),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                SettingsCard(
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(l10n.defaultTheme),
                        leading: Icon(Icons.light_mode_outlined,
                            semanticLabel: l10n.defaultTheme),
                        trailing: DropdownButton<ThemeMode>(
                          value: settings.themeMode,
                          onChanged: (ThemeMode? value) {
                            if (value == null) return;
                            HapticFeedback.lightImpact();
                            settings.setThemeMode(value);
                          },
                          items: ThemeMode.values
                              .map((mode) => DropdownMenuItem(
                                    value: mode,
                                    child: Text(_themeModeLabel(l10n, mode)),
                                  ))
                              .toList(),
                        ),
                      ),
                      SwitchSettingTile(
                        icon: Icons.color_lens_outlined,
                        title: l10n.customMaterialColor,
                        value: settings.useCustomColor,
                        onChanged: settings.setUseCustomColor,
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 750),
                        curve: Curves.easeInOut,
                        height: settings.useCustomColor ? 70 : 0,
                        child: Visibility(
                          visible: settings.useCustomColor,
                          child: ColorPickerTile(
                            colors: materialColors,
                            selectedColor: materialColors[settings.colorIndex],
                            onColorSelected: (color) => settings.setColorIndex(
                                materialColors.indexWhere((c) => c == color)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),
                SettingsCard(
                  child: ListTile(
                    leading: const Icon(Icons.widgets_outlined),
                    title: Text(l10n.widgetSettings),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pushNamed(context, '/widget_settings');
                    },
                  ),
                ),
                const SizedBox(height: 12.0),
                SettingsCard(
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(l10n.showSeconds),
                        leading: Icon(Icons.schedule,
                            semanticLabel: l10n.showSeconds),
                        subtitle: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l10n.worldClock),
                            SettingsSwitch(
                              onIcon: Icons.public,
                              offIcon: Icons.public_off,
                              value: settings.showSeconds,
                              onChanged: settings.setShowSeconds,
                            ),
                            Text(l10n.local),
                            SettingsSwitch(
                              onIcon: Icons.location_on,
                              offIcon: Icons.location_off,
                              value: settings.showSecondsLocal,
                              onChanged: settings.setShowSecondsLocal,
                            ),
                          ],
                        ),
                      ),
                      SwitchSettingTile(
                        icon: Icons.travel_explore,
                        title: l10n.use24hrFormat,
                        value: settings.use24hr,
                        onChanged: (value) {
                          settings.setUse24hr(value);
                          HomeWidgetService.updateTimeFormat(value);
                        },
                      ),
                      SwitchSettingTile(
                        icon: Icons.thermostat,
                        title: l10n.useFahrenheit,
                        value: settings.useFahrenheit,
                        onChanged: settings.setUseFahrenheit,
                      ),
                      SwitchSettingTile(
                        icon: Icons.info_outline,
                        title: l10n.displayMoreInfo,
                        value: settings.showMoreInfo,
                        onChanged: settings.setShowMoreInfo,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),
                SettingsCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: WttrServerTile(
                      controller: _urlController,
                      isValid: _isValidUrl,
                      hint: settings.wttrServer,
                      onChanged: (value) => setState(
                        () => _isValidUrl = WttrServerTile.isValidUrl(value),
                      ),
                      onSave: () => _saveUrl(l10n),
                      onReset: () => _resetUrl(l10n),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          onPressed: () => _close(l10n),
          child: Icon(Icons.check, semanticLabel: l10n.ok),
        ),
      ),
    );
  }
}
