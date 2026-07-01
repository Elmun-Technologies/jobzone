import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/widgets/snackbars.dart';
import '../application/cv_providers.dart';
import '../domain/cv_models.dart';

/// Resume landing (SuperJob-style): premium service cards across the top, then
/// either the seeker's uploaded resumes or an empty-state prompt to add one.
/// Upload/manage itself lives in [ResumePage] (Routes.profileResume).
class ResumeHomePage extends ConsumerWidget {
  const ResumeHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(resumesControllerProvider);
    final resumes = async.value ?? const <Resume>[];
    final loading = async.isLoading && !async.hasValue;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.sectionResume),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                children: [
                  SizedBox(
                    height: 128,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      children: [
                        _ServiceCard(
                          icon: Icons.description_outlined,
                          title: l.svcReadyTitle,
                          body: l.svcReadyBody,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _ServiceCard(
                          icon: Icons.headset_mic_outlined,
                          title: l.svcCareerTitle,
                          body: l.svcCareerBody,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _ServiceCard(
                          icon: Icons.work_outline_rounded,
                          title: l.svcSupportTitle,
                          body: l.svcSupportBody,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.xxxl),
                      child: JzLoader(),
                    )
                  else if (resumes.isEmpty)
                    const _EmptyResume()
                  else
                    _ResumeList(resumes: resumes),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A premium-service upsell card (order resume / career consult / search help).
/// The services aren't live yet, so a tap surfaces a "coming soon" message.
class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 250,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => showInfoSnack(context, context.l10n.comingSoon),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        body,
                        style: context.text.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.chipBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: colors.primary, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Prompt shown when the seeker has no resume yet.
class _EmptyResume extends StatelessWidget {
  const _EmptyResume();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: JzEmptyState(
        icon: Icons.description_outlined,
        title: l.resumeEmptyTitle,
        message: l.resumeEmptyBody,
        action: JzPrimaryButton(
          label: l.resumeCreate,
          icon: Icons.add_rounded,
          onPressed: () => context.push(Routes.profileResume),
        ),
      ),
    );
  }
}

/// The seeker's uploaded resumes, with a shortcut to add or manage them.
class _ResumeList extends StatelessWidget {
  const _ResumeList({required this.resumes});
  final List<Resume> resumes;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.myResumes, style: context.text.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          for (final r in resumes)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Material(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () => context.push(Routes.profileResume),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf_rounded,
                          color: colors.danger,
                          size: 28,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (r.sizeText != null)
                                Text(
                                  r.sizeText!,
                                  style: context.text.bodySmall?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => context.push(Routes.profileResume),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              side: BorderSide(color: colors.border),
            ),
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(l.uploadResume),
          ),
        ],
      ),
    );
  }
}
