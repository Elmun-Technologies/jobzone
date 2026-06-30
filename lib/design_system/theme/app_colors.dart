import 'package:flutter/material.dart';

/// Semantic color tokens, exposed as a [ThemeExtension] so widgets read
/// `Theme.of(context).extension<JzColors>()!` (see the `context.colors`
/// extension in `app_theme.dart`). Yolla brand: paper-white / ink-black
/// surfaces, soft fog-gray borders, and Yolla Volt (#C7FB00) as the accent.
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

  // Yolla — Siyoh Qora ink is the high-contrast "primary" (buttons, text,
  // active foregrounds); Yolla Volt is the vivid accent fill, mapped onto the
  // existing `gold` token (bright in both themes, always paired with ink text).
  static const Color _ink = Color(0xFF0A0A0A);
  static const Color _paper = Color(0xFFF3F3F1);
  static const Color _volt = Color(0xFFC7FB00);

  static const JzColors light = JzColors(
    primary: _ink,
    onPrimary: Colors.white,
    accent: _volt,
    gold: _volt,
    onGold: _ink,
    background: Color(0xFFFFFFFF),
    surface: Colors.white,
    surfaceVariant: Color(0xFFF3F3F1),
    border: Color(0xFFE2E2DE),
    textPrimary: _ink,
    textSecondary: Color(0xFF54544F),
    success: Color(0xFF16A34A),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFDC2626),
    chipBackground: Color(0xFFF3F3F1),
  );

  static const JzColors dark = JzColors(
    primary: _paper,
    onPrimary: _ink,
    accent: _volt,
    gold: _volt,
    onGold: _ink,
    background: _ink,
    surface: Color(0xFF161616),
    surfaceVariant: Color(0xFF1F1F1D),
    border: Color(0xFF2A2A27),
    textPrimary: _paper,
    textSecondary: Color(0xFFB8B8B2),
    success: Color(0xFF22C55E),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    chipBackground: Color(0xFF1F1F1D),
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
