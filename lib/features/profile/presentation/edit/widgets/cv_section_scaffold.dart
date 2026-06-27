import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../design_system/design_system.dart';
import '../../../../../localization/l10n_extension.dart';

/// List screen for a CV section: handles loading/error/empty, renders each
/// entry through [itemBuilder], and exposes an "Add" FAB.
class CvSectionScaffold<T> extends StatelessWidget {
  const CvSectionScaffold({
    super.key,
    required this.title,
    required this.async,
    required this.itemBuilder,
    required this.onAdd,
    required this.emptyTitle,
    required this.emptyBody,
    this.emptyIcon = Icons.add_circle_outline_rounded,
  });

  final String title;
  final AsyncValue<List<T>> async;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final VoidCallback onAdd;
  final String emptyTitle;
  final String emptyBody;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return JzScaffold(
      title: title,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded),
        label: Text(l.add),
      ),
      body: async.when(
        loading: () => const JzLoader(),
        error: (_, _) =>
            JzErrorState(title: l.errorTitle, message: l.errUnknown),
        data: (items) => items.isEmpty
            ? JzEmptyState(
                icon: emptyIcon,
                title: emptyTitle,
                message: emptyBody,
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  // leave room for the FAB
                  AppSpacing.xxl * 2,
                ),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (c, i) => itemBuilder(c, items[i]),
              ),
      ),
    );
  }
}

/// Consistent card for a CV entry: title, subtitle line(s), edit chevron.
class CvEntryCard extends StatelessWidget {
  const CvEntryCard({
    super.key,
    required this.title,
    this.subtitle,
    this.detail,
    required this.onTap,
    this.leadingIcon,
  });

  final String title;
  final String? subtitle;
  final String? detail;
  final VoidCallback onTap;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, color: colors.primary),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.titleSmall),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      style: context.text.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  if (detail != null && detail!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        detail!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}
