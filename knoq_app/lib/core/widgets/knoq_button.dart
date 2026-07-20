import 'package:flutter/material.dart';

enum KnoqButtonType { primary, secondary, danger }

class KnoqButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final KnoqButtonType type;
  final bool isLoading;

  const KnoqButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = KnoqButtonType.primary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = onPressed == null || isLoading;

    switch (type) {
      case KnoqButtonType.primary:
        return _buildElevated(theme, theme.colorScheme.primary, theme.colorScheme.onPrimary, isDisabled);
      case KnoqButtonType.secondary:
        return _buildOutlined(theme, isDisabled);
      case KnoqButtonType.danger:
        return _buildElevated(theme, theme.colorScheme.error, theme.colorScheme.onError, isDisabled);
    }
  }

  Widget _buildElevated(ThemeData theme, Color bg, Color fn, bool isDisabled) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fn,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: isDisabled ? null : onPressed,
      child: _buildChild(theme),
    );
  }

  Widget _buildOutlined(ThemeData theme, bool isDisabled) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        side: BorderSide(color: theme.colorScheme.primary),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: isDisabled ? null : onPressed,
      child: _buildChild(theme),
    );
  }

  Widget _buildChild(ThemeData theme) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            type == KnoqButtonType.secondary 
              ? theme.colorScheme.primary 
              : theme.colorScheme.onPrimary
          ),
        ),
      );
    }
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}
