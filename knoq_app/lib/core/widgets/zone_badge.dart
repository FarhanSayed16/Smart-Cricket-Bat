import 'package:flutter/material.dart';
import 'package:knoq_app/core/constants/app_colors.dart';

class ZoneBadge extends StatelessWidget {
  final String zone;
  final bool showIcon;

  const ZoneBadge({
    super.key,
    required this.zone,
    this.showIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getZoneColor(context, zone);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(Icons.sports_cricket, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            zone,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
