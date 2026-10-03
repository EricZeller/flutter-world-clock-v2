import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Elevated card that groups related settings.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 40,
      shadowColor: Theme.of(context).colorScheme.primary,
      child: child,
    );
  }
}

/// Switch with icons in its thumb and haptic feedback on change.
class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.onIcon = Icons.check,
    this.offIcon = Icons.close,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData onIcon;
  final IconData offIcon;

  @override
  Widget build(BuildContext context) {
    return Switch(
      thumbIcon: WidgetStateProperty.resolveWith<Icon?>(
        (states) => Icon(
          states.contains(WidgetState.selected) ? onIcon : offIcon,
        ),
      ),
      value: value,
      onChanged: (value) {
        HapticFeedback.lightImpact();
        onChanged(value);
      },
    );
  }
}

/// List tile with a leading icon and a [SettingsSwitch] as trailing widget.
/// Tapping anywhere on the tile toggles the switch.
class SwitchSettingTile extends StatelessWidget {
  const SwitchSettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: ListTile(
        leading: Icon(icon, semanticLabel: title),
        title: Text(title),
        trailing: SettingsSwitch(value: value, onChanged: onChanged),
        onTap: () {
          HapticFeedback.lightImpact();
          onChanged(!value);
        },
      ),
    );
  }
}

void showInfoDialog(BuildContext context, String title, String content) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: content.isEmpty ? null : Text(content),
        actions: [
          ElevatedButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}
