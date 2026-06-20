import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../application/bookmarks_controller.dart';
import '../../domain/job.dart';
import '../util/job_labels.dart';
import 'bookmark_confirm_sheet.dart';

/// Job summary card used across Home, See-all, Bookmarks and Search. Tapping
/// opens details; the bookmark toggle is wired to [bookmarksControllerProvider].
/// Pass [width] to use it inside a horizontal carousel.
class JobCard extends ConsumerWidget {
  const JobCard({super.key, required this.job, this.width});

  final Job job;
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final colors = context.colors;
    final bookmarked =
        ref.watch(bookmarksControllerProvider).value?.contains(job.id) ?? false;
    final tags = [
      ?jobTypeLabel(context, job.jobType),
      ?workingModelLabel(context, job.workingModel),
      ?experienceLabel(context, job.experienceLevel),
    ];

    return GestureDetector(
      onTap: () => context.push(Routes.jobDetails(job.id)),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Logo(name: job.companyName, url: job.companyLogoUrl),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (job.isBoosted) ...[
                        const JzTopBadge(),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                      Text(
                        job.title,
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              job.companyName,
                              style: context.text.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (job.companyVerified) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: colors.primary,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: bookmarked ? l.removeBookmark : l.addBookmark,
                  child: InkResponse(
                    onTap: () async {
                      final notifier = ref.read(
                        bookmarksControllerProvider.notifier,
                      );
                      if (!bookmarked) {
                        notifier.toggle(job.id);
                        return;
                      }
                      final remove = await showRemoveBookmarkSheet(
                        context,
                        job,
                      );
                      if (remove == true) notifier.toggle(job.id);
                    },
                    child: Icon(
                      bookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: bookmarked ? colors.primary : colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (job.locationText.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: colors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      job.locationText,
                      style: context.text.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (tags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [for (final t in tags) _Tag(t)],
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(color: colors.border, height: 1),
            ),
            Row(
              children: [
                Expanded(child: _Applicants(count: job.applicantsCount)),
                if (job.salaryText != null)
                  Flexible(
                    child: RichText(
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        text: job.salaryText,
                        style: context.text.titleSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                        children: [
                          if (job.salaryPeriodSuffix != null)
                            TextSpan(
                              text: ' ${job.salaryPeriodSuffix}',
                              style: context.text.bodySmall?.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.name, this.url});
  final String name;
  final String? url;

  static const _palette = [
    Color(0xFF3A36DB),
    Color(0xFF1A1A1A),
    Color(0xFF0EA5E9),
    Color(0xFF16A34A),
    Color(0xFFDB2777),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _palette[name.hashCode.abs() % _palette.length];
    final letter = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
    final fallback = ColoredBox(
      color: color,
      child: Center(
        child: Text(
          letter,
          style: context.text.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        height: 48,
        width: 48,
        child: (url == null || url!.isEmpty)
            ? fallback
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(color: colors.textPrimary),
      ),
    );
  }
}

/// Overlapping applicant avatars + "N Applicants".
class _Applicants extends StatelessWidget {
  const _Applicants({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const n = 3;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18.0 * n + 6,
          height: 24,
          child: Stack(
            children: [
              for (var i = 0; i < n; i++)
                Positioned(
                  left: i * 16.0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.surface, width: 1.5),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            '$count ${context.l10n.applicants}',
            style: context.text.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
