import 'package:flutter/material.dart';

class SwingSpeedDisplay extends StatelessWidget {
  final double? swing;

  const SwingSpeedDisplay({
    super.key,
    required this.swing,
  });

  @override
  Widget build(BuildContext context) {
    // If swing is null or 0 -> renders nothing according to phase plan rule
    if (swing == null || swing! <= 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.compare_arrows_rounded, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Swing: ${swing!.toStringAsFixed(1)}°/s',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
