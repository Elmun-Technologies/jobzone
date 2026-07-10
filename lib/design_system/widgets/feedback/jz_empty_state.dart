import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../motion/jz_motion.dart';

/// Friendly empty/placeholder state with an icon, title and optional action.
/// Eases in (fade + slight rise) so an empty screen still feels alive.
class JzEmptyState extends StatelessWidget {
  const JzEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: JzFadeSlideIn(
        dy: 14,
        scaleFrom: 0.96,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.chipBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: colors.primary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: context.text.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  style: context.text.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppSpacing.xl),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
