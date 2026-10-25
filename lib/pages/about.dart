import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/theme/app_theme.dart';

final _versionLine = RegExp(
  r'''^version:[ \t]*["']?([^\s"'#]+)''',
  multiLine: true,
);

/// Returns the app version from the top-level `version:` entry of
/// [pubspec] without the build number (`1.2.3+45` -> `1.2.3`).
///
/// Only this one line is needed, so a regular expression replaces a full
/// YAML parser, which kept the `yaml` package out of the app binary.
String parseAppVersion(String pubspec) {
  final match = _versionLine.firstMatch(pubspec);
  if (match == null) {
    throw const FormatException('No version entry in pubspec.yaml');
  }
  return match.group(1)!.split('+').first;
}

Future<String> getAppVersion() async {
  final pubspec = await rootBundle.loadString('pubspec.yaml');
  return parseAppVersion(pubspec);
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
              Text(l10n.dataSources, style: heading),
              const SizedBox(height: 10),
              Text(l10n.dataSourcesDescription, style: body),
              const SizedBox(height: 4),
              for (final source in _dataSources(l10n))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    source.name,
                    style: body.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    source.credit,
                    style: TextStyle(color: colorScheme.onSecondaryContainer),
                  ),
                  trailing: Icon(
                    Icons.open_in_new,
                    semanticLabel: l10n.openWebsite,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  onTap: () => _launchUrl(source.url),
                ),
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

/// The data and fonts of others the app is made of, credited as their
/// licenses ask, with the sites to find them at. The same sources are
/// listed in the README.
List<({String name, String credit, Uri url})> _dataSources(
  AppLocalizations l10n,
) => [
  (
    name: 'GeoNames',
    credit: l10n.geoNamesCredit,
    url: Uri.parse('https://www.geonames.org'),
  ),
  (
    name: 'Unicode CLDR',
    credit: l10n.cldrCredit,
    url: Uri.parse('https://cldr.unicode.org'),
  ),
  (
    name: 'IANA Time Zone Database',
    credit: l10n.timeZonesCredit,
    url: Uri.parse('https://www.iana.org/time-zones'),
  ),
  (
    name: 'flagpedia.net',
    credit: l10n.flagsCredit,
    url: Uri.parse('https://flagpedia.net'),
  ),
  (
    name: 'wttr.in',
    credit: l10n.weatherCredit,
    url: Uri.parse('https://wttr.in'),
  ),
  (
    name: 'Google Fonts',
    credit: l10n.fontsCredit,
    url: Uri.parse('https://fonts.google.com'),
  ),
];

Future<void> _launchUrl(Uri url) async {
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  }
}
