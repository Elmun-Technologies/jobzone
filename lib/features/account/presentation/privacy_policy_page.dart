import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;

    return JzScaffold(
      title: l.privacyPolicy,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            l.privacyUpdated,
            style: context.text.labelSmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l.privacyIntro, style: context.text.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          _Section(title: l.privacyDataTitle, body: l.privacyDataBody),
          _Section(title: l.privacyUsageTitle, body: l.privacyUsageBody),
          _Section(title: l.privacyRightsTitle, body: l.privacyRightsBody),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
