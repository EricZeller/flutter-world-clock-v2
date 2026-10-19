import 'package:flutter/material.dart';

/// Small tinted pill with an icon, used for extra info on the home screen.
class InfoChip extends StatelessWidget {
  const InfoChip({super.key, this.icon, this.symbol, required this.label})
      : assert((icon == null) != (symbol == null));

  final IconData? icon;

  /// Emoji shown instead of an [icon].
  final String? symbol;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (symbol case final symbol?)
            Text(symbol, style: const TextStyle(fontSize: 13))
          else
            Icon(icon, size: 15, color: colorScheme.primary),
          const SizedBox(width: 6),
          // Wraps long labels, e.g. moon phases with large fonts.
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
