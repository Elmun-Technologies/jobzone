import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final faqs = <(String, String)>[
      (l.faqQ1, l.faqA1),
      (l.faqQ2, l.faqA2),
      (l.faqQ3, l.faqA3),
      (l.faqQ4, l.faqA4),
    ];

    return JzScaffold(
      title: l.helpCenter,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(l.faqTitle, style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...faqs.map(
            (f) => Card(
              elevation: 0,
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: colors.border),
              ),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ExpansionTile(
                shape: const Border(),
                title: Text(f.$1, style: context.text.titleSmall),
                childrenPadding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      f.$2,
                      style: context.text.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Icon(Icons.support_agent_rounded, color: colors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.contactSupport, style: context.text.titleSmall),
                      Text(
                        l.contactSupportBody,
                        style: context.text.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
