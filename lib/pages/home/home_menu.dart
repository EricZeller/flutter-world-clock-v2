import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';

class HomeMenu extends StatelessWidget {
  const HomeMenu({
    super.key,
    required this.onOpenSettings,
    required this.onChangeCity,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onChangeCity;

  static final Uri _githubUrl =
      Uri.parse('https://github.com/EricZeller/flutter-world-clock-v2');
  static final Uri _issueUrl =
      Uri.parse('https://github.com/EricZeller/flutter-world-clock-v2/issues');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      onSelected: (String result) {
        HapticFeedback.lightImpact();
        switch (result) {
          case 'settings':
            onOpenSettings();
          case 'changeCity':
            onChangeCity();
          case 'about':
            Navigator.pushNamed(context, '/about');
          case 'source_code':
            _launchUrl(_githubUrl);
          case 'bug_report':
            _launchUrl(_issueUrl);
        }
      },
      icon: const Icon(Icons.more_vert),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        _item('settings', l10n.settings, Icons.settings),
        _item('changeCity', l10n.changeCity, Icons.edit_location_alt),
        _item('about', l10n.about, Icons.info),
        _item('source_code', l10n.sourceCode, Icons.code),
        _item('bug_report', l10n.reportBug, Icons.bug_report),
      ],
    );
  }

  PopupMenuItem<String> _item(String value, String label, IconData icon) {
    return PopupMenuItem<String>(
      value: value,
      child: ListTile(
        title: Text(label),
        leading: Icon(icon, semanticLabel: label),
      ),
    );
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}
