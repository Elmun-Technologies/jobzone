import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';

/// The kind of trust signal a [JzTrustBadge] conveys.
enum JzTrustKind { phone, worker, employer, agency }

/// A two-sided trust badge: verified employer / licensed agency / verified
/// worker / phone-verified. Distinct from the gold [JzTopBadge] (paid promo) —
/// trust uses blue/green/indigo. Pass [label] for a pill; omit it for an
/// icon-only marker (e.g. inline next to a name).
class JzTrustBadge extends StatelessWidget {
  const JzTrustBadge({super.key, required this.kind, this.label});

  final JzTrustKind kind;
  final String? label;

  @override
  Widget build(BuildContext context) {
    // Brighter variants in dark mode — the original green/indigo were near
    // the dark surface luminance, so pill text was barely legible on dark.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final green = dark ? const Color(0xFF34D399) : const Color(0xFF0E9F6E);
    final indigo = dark ? const Color(0xFFA78BFA) : const Color(0xFF6D28D9);
    final (IconData icon, Color color) = switch (kind) {
      JzTrustKind.phone => (Icons.phone_iphone_rounded, green),
      JzTrustKind.worker => (Icons.verified_user_rounded, green),
      JzTrustKind.employer => (Icons.verified_rounded, context.colors.primary),
      JzTrustKind.agency => (Icons.workspace_premium_rounded, indigo),
    };
    if (label == null) {
      return Icon(icon, size: 16, color: color);
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(
            label!,
            style: context.text.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
