import 'package:flutter/material.dart';
import 'package:knoq_app/core/widgets/knoq_button.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? illustration;
  final String? buttonText;
  final VoidCallback? onButtonPress;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.illustration,
    this.buttonText,
    this.onButtonPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (illustration != null) ...[
            illustration!,
            const SizedBox(height: 24),
          ],
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (buttonText != null && onButtonPress != null) ...[
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: KnoqButton(
                text: buttonText!,
                onPressed: onButtonPress,
                type: KnoqButtonType.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
