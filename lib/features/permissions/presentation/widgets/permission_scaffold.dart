import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

/// Shared layout for the permission-request screens (matches the Figma
/// reference): a large icon in a soft circle, centered title/body, a primary
/// pill action and a single secondary text action.
class PermissionScaffold extends StatelessWidget {
  const PermissionScaffold({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        // Scrolls when the content can't fit (short screens / large font
        // scale) so the Spacer-centred layout never overflows.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      const Spacer(flex: 3),
                      Container(
                        height: 130,
                        width: 130,
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 56, color: colors.primary),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        title,
                        style: context.text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
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
                      const SizedBox(height: AppSpacing.xxl),
                      JzPrimaryButton(
                        label: primaryLabel,
                        onPressed: onPrimary,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: onSecondary,
                        child: Text(
                          secondaryLabel,
                          style: context.text.titleMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(flex: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
