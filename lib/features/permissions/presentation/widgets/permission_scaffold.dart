import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

/// Shared layout for the permission-request screens: a large icon, title/body,
/// a primary action, an optional secondary action, and a skip button.
class PermissionScaffold extends StatelessWidget {
  const PermissionScaffold({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    required this.skipLabel,
    required this.onSkip,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String skipLabel;
  final VoidCallback onSkip;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return JzScaffold(
      showBack: false,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const Spacer(),
            Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(
                color: colors.chipBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: colors.primary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              title,
              style: context.text.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              style: context.text.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            JzPrimaryButton(label: primaryLabel, onPressed: onPrimary),
            if (secondaryLabel != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel!),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: onSkip, child: Text(skipLabel)),
          ],
        ),
      ),
    );
  }
}
