import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Convenient access to design tokens from any widget.
extension JzThemeX on BuildContext {
  JzColors get colors => Theme.of(this).extension<JzColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
}

/// Builds the app's light/dark [ThemeData] from the [JzColors] tokens.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light, JzColors.light);
  static ThemeData dark() => _build(Brightness.dark, JzColors.dark);

  static ThemeData _build(Brightness brightness, JzColors c) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: c.primary,
          brightness: brightness,
        ).copyWith(
          primary: c.primary,
          onPrimary: c.onPrimary,
          surface: c.surface,
          error: c.danger,
        );

    final textTheme = AppTypography.textTheme.apply(
      bodyColor: c.textPrimary,
      displayColor: c.textPrimary,
      fontFamily: AppTypography.fontFamily,
    );

    OutlinedBorder rounded([double r = AppRadius.md]) =>
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));

    // The reference design uses fully-rounded (pill) CTAs with a bold label.
    const pill = StadiumBorder();
    final ctaLabel = textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,
      dividerColor: c.border,
      extensions: <ThemeExtension<dynamic>>[c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.primary.withValues(alpha: 0.5),
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          textStyle: ctaLabel,
          shape: pill,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          minimumSize: const Size.fromHeight(54),
          textStyle: ctaLabel,
          shape: pill,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: c.border),
          textStyle: ctaLabel,
          shape: pill,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: c.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.danger, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.chipBackground,
        labelStyle: textTheme.labelMedium?.copyWith(color: c.textPrimary),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: Colors.transparent,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? c.primary
                : c.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall!.copyWith(
            color: states.contains(WidgetState.selected)
                ? c.primary
                : c.textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: c.surface),
        shape: rounded(AppRadius.md),
      ),
    );
  }
}
