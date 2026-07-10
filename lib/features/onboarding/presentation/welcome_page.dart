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

/// Soft blob backdrop with two floating hashtag tags.
class _WelcomeArt extends StatelessWidget {
  const _WelcomeArt();

  @override
  Widget build(BuildContext context) {
    final blob = const Color(0xFFE9EAEE);
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Positioned(top: -40, right: -60, child: _Blob(220, blob)),
          Positioned(
            top: 120,
            left: -70,
            child: _Blob(180, blob.withValues(alpha: 0.6)),
          ),
          Positioned(
            bottom: 10,
            right: -40,
            child: _Blob(160, blob.withValues(alpha: 0.7)),
          ),
          // Blue-collar, localized tags — the first screen should speak the
          // product's language, not "#Developer/#Designer".
          Align(
            alignment: const Alignment(0.15, -0.35),
            child: _Tag(
              context.l10n.welcomeTagChef,
              bg: context.colors.primary,
              fg: Colors.white,
            ),
          ),
          Align(
            alignment: const Alignment(-0.25, 0.45),
            child: _Tag(
              context.l10n.welcomeTagDriver,
              bg: context.colors.gold,
              fg: context.colors.onGold,
            ),
          ),
        ],
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

class _Tag extends StatelessWidget {
  const _Tag(this.label, {required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: context.text.titleMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
