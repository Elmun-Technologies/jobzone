import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/config/env.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';

/// Welcome screen — matches the Figma reference: a soft decorative header with
/// floating hashtag tags, a two-tone headline, the primary CTA, and a
/// sign-in link.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Scaffold(
      body: Column(
        children: [
          const Expanded(child: _WelcomeArt()),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HighlightText(
                  l.welcomeTitle,
                  textAlign: TextAlign.center,
                  highlightColor: colors.primary,
                  style: context.text.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l.welcomeSubtitle,
                  style: context.text.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                JzPrimaryButton(
                  label: l.getStarted,
                  onPressed: () => context.go(
                    Env.hasSupabase ? Routes.createAccount : Routes.home,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l.alreadyHaveAccount,
                      style: context.text.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    GestureDetector(
                      onTap: () => context.push(Routes.signIn),
                      child: Text(
                        l.signIn,
                        style: context.text.bodyMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft blob backdrop, a central brand mark, and a scatter of floating,
/// blue-collar category tags. The tags speak the product's language
/// (#Oshpaz/#Haydovchi…, localized), and everything drifts in with a staggered
/// entrance so the first screen feels alive instead of a big white void.
///
/// Positions use fractional [Alignment] (not fixed pixels), so the composition
/// scales with the viewport on every device and can't overflow.
class _WelcomeArt extends StatelessWidget {
  const _WelcomeArt();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l = context.l10n;
    const blob = Color(0xFFEDEEF2);

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          // Depth blobs — brand-tinted, not flat grey, for a warmer backdrop.
          Positioned(top: -50, right: -60, child: _Blob(220, blob)),
          Positioned(
            top: 80,
            left: -70,
            child: _Blob(190, colors.primary.withValues(alpha: 0.14)),
          ),
          Positioned(
            bottom: -10,
            right: -50,
            child: _Blob(170, colors.gold.withValues(alpha: 0.16)),
          ),
          Positioned(bottom: 70, left: -44, child: _Blob(120, blob)),

          // Central brand mark — a gentle focal point so the hero reads as
          // composed, not empty.
          Align(
            alignment: const Alignment(0, -0.06),
            child: JzFadeSlideIn(
              duration: const Duration(milliseconds: 520),
              dy: 0,
              scaleFrom: 0.72,
              child: const _BrandMark(),
            ),
          ),

          // Blue-collar, localized tags scattered around the mark, each drifting
          // in on its own beat. Colours rotate through the brand palette.
          _FloatingTag(
            l.welcomeTagChef,
            const Alignment(-0.62, -0.68),
            bg: colors.primary,
            fg: colors.onPrimary,
            delayMs: 120,
          ),
          _FloatingTag(
            l.welcomeTagDriver,
            const Alignment(0.66, -0.5),
            bg: colors.gold,
            fg: colors.onGold,
            delayMs: 200,
            scale: 1.06,
          ),
          _FloatingTag(
            l.welcomeTagCourier,
            const Alignment(0.74, 0.04),
            bg: colors.textPrimary,
            fg: Colors.white,
            delayMs: 280,
            scale: 0.9,
          ),
          _FloatingTag(
            l.welcomeTagWaiter,
            const Alignment(-0.8, -0.02),
            bg: colors.surface,
            fg: colors.textPrimary,
            border: true,
            delayMs: 360,
            scale: 0.9,
          ),
          _FloatingTag(
            l.welcomeTagSeller,
            const Alignment(-0.5, 0.64),
            bg: colors.gold,
            fg: colors.onGold,
            delayMs: 440,
          ),
          _FloatingTag(
            l.welcomeTagBuilder,
            const Alignment(0.5, 0.62),
            bg: colors.primary,
            fg: colors.onPrimary,
            delayMs: 520,
            scale: 1.02,
          ),
        ],
      ),
    );
  }
}

/// The app-icon tile as a soft-shadowed squircle — self-contained artwork, so
/// it reads correctly in both light and dark themes.
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Image.asset(
          'assets/icon/icon.png',
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          // Degrade to a brand tile if the asset can't decode, so the hero
          // never shows a broken-image glyph (and tests don't trip on it).
          errorBuilder: (context, _, _) =>
              Container(width: 96, height: 96, color: context.colors.primary),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob(this.size, this.color);
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.45),
      ),
    );
  }
}

/// A [_Tag] positioned by fractional [alignment] and revealed with a staggered
/// fade-and-scale entrance.
class _FloatingTag extends StatelessWidget {
  const _FloatingTag(
    this.label,
    this.alignment, {
    required this.bg,
    required this.fg,
    this.border = false,
    this.delayMs = 0,
    this.scale = 1.0,
  });

  final String label;
  final Alignment alignment;
  final Color bg;
  final Color fg;
  final bool border;
  final int delayMs;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: JzFadeSlideIn(
        delay: Duration(milliseconds: delayMs),
        dy: 14,
        scaleFrom: 0.6,
        child: _Tag(label, bg: bg, fg: fg, border: border, scale: scale),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(
    this.label, {
    required this.bg,
    required this.fg,
    this.border = false,
    this.scale = 1.0,
  });
  final String label;
  final Color bg;
  final Color fg;
  final bool border;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = context.text.titleMedium;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg * scale,
        vertical: AppSpacing.md * scale,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: border ? Border.all(color: colors.border) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: base?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: (base.fontSize ?? 16) * scale,
        ),
      ),
    );
  }
}
