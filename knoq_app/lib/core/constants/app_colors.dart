import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Tokens
  static const Color primaryLight = Color(0xFF00C853);
  static const Color secondaryLight = Color(0xFF1565C0);
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF0F0F0);
  static const Color onBackgroundLight = Color(0xFF1A1A1A);
  static const Color onSurfaceVariantLight = Color(0xFF6B6B6B);
  static const Color outlineLight = Color(0xFFE0E0E0);
  static const Color errorLight = Color(0xFFD32F2F);
  static const Color warningLight = Color(0xFFF57C00);

  // Dark Theme Tokens
  static const Color primaryDark = Color(0xFF66FFA6);
  static const Color secondaryDark = Color(0xFF64B5F6);
  static const Color backgroundDark = Color(0xFF0D0D0D);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color surfaceVariantDark = Color(0xFF252525);
  static const Color onBackgroundDark = Color(0xFFFFFFFF);
  static const Color onSurfaceVariantDark = Color(0xFF9E9E9E);
  static const Color outlineDark = Color(0xFF333333);
  static const Color errorDark = Color(0xFFFF5252);
  static const Color warningDark = Color(0xFFFFB300);

  // Base Zone Colors (Used in Light Theme)
  static const Color zoneSweet = Color(0xFF00C853);
  static const Color zoneTop = Color(0xFF2196F3);
  static const Color zoneLeft = Color(0xFFFF9800);
  static const Color zoneRight = Color(0xFF9C27B0);
  static const Color zoneBottom = Color(0xFFF44336);

  // Elevated Zone Colors (Used in Dark Theme for visibility)
  static const Color zoneSweetDark = Color(0xFF69F0AE);
  static const Color zoneTopDark = Color(0xFF64B5F6);
  static const Color zoneLeftDark = Color(0xFFFFB74D);
  static const Color zoneRightDark = Color(0xFFCE93D8);
  static const Color zoneBottomDark = Color(0xFFEF5350);

  /// Helper to get the correct zone color based on the current theme brightness
  static Color getZoneColor(BuildContext context, String zone) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lowerZone = zone.toLowerCase();
    
    switch (lowerZone) {
      case 'sweet':
        return isDark ? zoneSweetDark : zoneSweet;
      case 'top':
        return isDark ? zoneTopDark : zoneTop;
      case 'left':
        return isDark ? zoneLeftDark : zoneLeft;
      case 'right':
        return isDark ? zoneRightDark : zoneRight;
      case 'bottom':
        return isDark ? zoneBottomDark : zoneBottom;
      default:
        return isDark ? onSurfaceVariantDark : onSurfaceVariantLight;
    }
  }
}
