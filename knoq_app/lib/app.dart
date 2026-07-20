import 'package:flutter/material.dart';
import 'package:knoq_app/core/constants/app_colors.dart';
import 'package:knoq_app/core/constants/app_typography.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knoq_app/routing/app_router.dart';
import 'package:knoq_app/l10n/app_localizations.dart';

class KnoQApp extends ConsumerWidget {
  const KnoQApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Read theme mode preference from Hive, default to system
    final settingsBox = Hive.box('app_settings');
    return ValueListenableBuilder(
      valueListenable: settingsBox.listenable(keys: ['themeMode', 'language']),
      builder: (context, box, child) {
        final String themePref = box.get('themeMode', defaultValue: 'system');
        ThemeMode themeMode;
        if (themePref == 'light') {
          themeMode = ThemeMode.light;
        } else if (themePref == 'dark') {
          themeMode = ThemeMode.dark;
        } else {
          themeMode = ThemeMode.system;
        }
        final String langPref = box.get('language', defaultValue: 'en');
        Locale appLocale = Locale(langPref);

        return MaterialApp.router(
          title: 'KnoQ',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          routerConfig: router,
          locale: appLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? AppColors.primaryDark : AppColors.primaryLight,
      onPrimary: isDark ? AppColors.onBackgroundDark : AppColors.surfaceLight,
      secondary: isDark ? AppColors.secondaryDark : AppColors.secondaryLight,
      onSecondary: isDark ? AppColors.onBackgroundDark : AppColors.surfaceLight,
      error: isDark ? AppColors.errorDark : AppColors.errorLight,
      onError: isDark ? AppColors.onBackgroundDark : AppColors.surfaceLight,
      surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      onSurface: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
      surfaceContainerHighest: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
      onSurfaceVariant: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariantLight,
      outline: isDark ? AppColors.outlineDark : AppColors.outlineLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: AppTypography.getTextTheme(brightness),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
