import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';

/// Gold "TOP" badge for promoted (boosted) jobs. Brand yellow accent (#FFC629)
/// with dark text so it pops against cards.
class JzTopBadge extends StatelessWidget {
  const JzTopBadge({super.key, this.label = 'TOP'});

  final String label;

  static const _gold = Color(0xFFFFC629);
  static const _ink = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: _gold,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 13, color: _ink),
          const SizedBox(width: 2),
          Text(
            label,
            style: context.text.labelSmall?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
