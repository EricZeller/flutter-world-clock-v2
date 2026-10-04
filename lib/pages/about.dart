import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/theme/app_theme.dart';
import 'package:yaml/yaml.dart';

Future<String> getAppVersion() async {
  final pubspec = await rootBundle.loadString('pubspec.yaml');
  final yamlMap = loadYaml(pubspec);
  final version = yamlMap['version'] as String;
  return version.split('+').first; // Entfernt die Build-Nummer
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final heading = TextStyle(
      fontFamily: AppTheme.accentFontFamily,
      fontSize: 24,
      color: colorScheme.onSecondaryContainer,
    );
    final body = TextStyle(fontSize: 18, color: colorScheme.onSecondaryContainer);
    final divider = Divider(
      height: 60.0,
      thickness: 2,
      color: colorScheme.secondary,
    );

    return Scaffold(
      backgroundColor: colorScheme.secondaryContainer,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          l10n.aboutThisApp,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: colorScheme.onSecondaryContainer,
          ),
        ),
        backgroundColor: colorScheme.secondaryContainer,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, semanticLabel: l10n.ok),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.appTitle, style: heading),
              FutureBuilder<String>(
                future: getAppVersion(),
                builder: (context, snapshot) => Text(
                  snapshot.hasData ? l10n.currentVersion(snapshot.data!) : '',
                  style: TextStyle(
                    fontSize: 20,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(l10n.aboutDescription, style: body),
              divider,
              Text(l10n.license, style: heading),
              const SizedBox(height: 10),
              Text(l10n.licenseDescription, style: body),
              divider,
              Text(l10n.contact, style: heading),
              const SizedBox(height: 10),
              Text(l10n.contactDescription, style: body),
            ],
          ),
        ),
      ),
    );
  }
}
