import 'package:flutter/material.dart';

/// Semantic color tokens, exposed as a [ThemeExtension] so widgets read
/// `Theme.of(context).extension<JzColors>()!` (see the `context.colors`
/// extension in `app_theme.dart`). Matches the Figma reference: clean white
/// surfaces, soft borders, a royal-indigo accent (#3A36DB).
@immutable
class JzColors extends ThemeExtension<JzColors> {
  const JzColors({
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.gold,
    required this.onGold,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.chipBackground,
  });

  final Color primary;
  final Color onPrimary;
  final Color accent;

  /// Brand gold (filter button, TOP/boost badges, ratings). Vivid in both
  /// light and dark, so it — and its dark [onGold] foreground — are fixed.
  final Color gold;
  final Color onGold;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color success;
  final Color warning;
  final Color danger;
  final Color chipBackground;

  // Figma reference primary (royal indigo) + a lighter tint for dark mode.
  static const Color _indigo = Color(0xFF3A36DB);
  static const Color _indigoDark = Color(0xFF6C63FF);

  static const JzColors light = JzColors(
    primary: _indigo,
    onPrimary: Colors.white,
    accent: Color(0xFF6366F1),
    gold: Color(0xFFFFC629),
    onGold: Color(0xFF1A1A1A),
    background: Color(0xFFF7F8FA),
    surface: Colors.white,
    surfaceVariant: Color(0xFFF1F3F6),
    border: Color(0xFFE6E8EC),
    textPrimary: Color(0xFF111418),
    textSecondary: Color(0xFF6B7280),
    success: Color(0xFF16A34A),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFDC2626),
    chipBackground: Color(0xFFEEF2FF),
  );

  static const JzColors dark = JzColors(
    primary: _indigoDark,
    onPrimary: Colors.white,
    accent: Color(0xFF818CF8),
    gold: Color(0xFFFFC629),
    onGold: Color(0xFF1A1A1A),
    background: Color(0xFF0E1116),
    surface: Color(0xFF171A21),
    surfaceVariant: Color(0xFF1F242D),
    border: Color(0xFF2A2F39),
    textPrimary: Color(0xFFF3F4F6),
    textSecondary: Color(0xFF9CA3AF),
    success: Color(0xFF22C55E),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    chipBackground: Color(0xFF1E2433),
  );

  @override
  JzColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? accent,
    Color? gold,
    Color? onGold,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? success,
    Color? warning,
    Color? danger,
    Color? chipBackground,
  }) {
    return JzColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      accent: accent ?? this.accent,
      gold: gold ?? this.gold,
      onGold: onGold ?? this.onGold,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      chipBackground: chipBackground ?? this.chipBackground,
    );
  }

  @override
  JzColors lerp(covariant ThemeExtension<JzColors>? other, double t) {
    if (other is! JzColors) return this;
    return JzColors(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      onGold: Color.lerp(onGold, other.onGold, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      chipBackground: Color.lerp(chipBackground, other.chipBackground, t)!,
    );
  }
}
