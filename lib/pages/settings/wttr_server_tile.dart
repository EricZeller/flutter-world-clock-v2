import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';

/// Text field to configure a custom wttr.in server.
class WttrServerTile extends StatelessWidget {
  const WttrServerTile({
    super.key,
    required this.controller,
    required this.isValid,
    required this.hint,
    required this.onChanged,
    required this.onSave,
    required this.onReset,
  });

  final TextEditingController controller;
  final bool isValid;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onSave;
  final VoidCallback onReset;

  static final _urlPattern =
      RegExp(r'^(https?:\/\/)([a-zA-Z0-9\-]+\.)+[a-zA-Z0-9\-]+$');

  static bool isValidUrl(String url) =>
      _urlPattern.hasMatch(url) && !url.endsWith('/');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final errorBorder = OutlineInputBorder(
      borderSide: BorderSide(color: colorScheme.error),
    );
    return ListTile(
      leading: Icon(Icons.link, semanticLabel: l10n.setWttrServer),
      title: TextField(
        controller: controller,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          suffixIcon: IconButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              onReset();
            },
            icon: const Icon(Icons.restart_alt_rounded),
          ),
          labelText: l10n.setWttrServer,
          hintText: hint,
          errorText: isValid ? null : l10n.invalidUrl,
          border: const OutlineInputBorder(),
          errorBorder: errorBorder,
          focusedErrorBorder: errorBorder,
        ),
        onChanged: onChanged,
        onSubmitted: (_) {
          HapticFeedback.lightImpact();
          onSave();
        },
      ),
      trailing: CircleAvatar(
        backgroundColor: colorScheme.primary,
        child: IconButton(
          color: colorScheme.onPrimary,
          icon: Icon(Icons.save_outlined, semanticLabel: l10n.urlSaved),
          onPressed: () {
            HapticFeedback.lightImpact();
            onSave();
          },
        ),
      ),
    );
  }
}
