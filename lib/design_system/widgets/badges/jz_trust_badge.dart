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
    final (IconData icon, Color color) = switch (kind) {
      JzTrustKind.phone => (
        Icons.phone_iphone_rounded,
        const Color(0xFF0E9F6E),
      ),
      JzTrustKind.worker => (
        Icons.verified_user_rounded,
        const Color(0xFF0E9F6E),
      ),
      JzTrustKind.employer => (Icons.verified_rounded, context.colors.primary),
      JzTrustKind.agency => (
        Icons.workspace_premium_rounded,
        const Color(0xFF6D28D9),
      ),
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
