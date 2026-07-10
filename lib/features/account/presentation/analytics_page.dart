import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../applications/application/applications_controller.dart';

/// Activity dashboard. Shows the REAL applied-jobs count; profile-view /
/// search-appearance metrics aren't tracked client-side yet, so instead of
/// the old fabricated chart and fake "viewers" list this page says so
/// honestly and will grow real widgets once tracking ships.
class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final colors = context.colors;
    final applied =
        ref.watch(applicationsControllerProvider).value?.length ?? 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.analytics),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  JzFadeSlideIn(
                    dy: 12,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          JzCountUp(
                            value: applied,
                            style: context.text.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l.appliedJobs,
                            style: context.text.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  JzEmptyState(
                    icon: Icons.insights_rounded,
                    title: l.analyticsSoonTitle,
                    message: l.analyticsSoonBody,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
