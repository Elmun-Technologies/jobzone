import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

/// Shared auth header: optional circular back button, a large centered title
/// and a centered subtitle. Segments wrapped in `*…*` in [subtitle] (e.g. an
/// email) render in the brand colour.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        if (showBack)
          Align(
            alignment: Alignment.centerLeft,
            child: JzCircleButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
        SizedBox(height: showBack ? AppSpacing.xl : AppSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: context.text.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        HighlightText(
          subtitle,
          textAlign: TextAlign.center,
          highlightColor: colors.primary,
          style: context.text.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}
