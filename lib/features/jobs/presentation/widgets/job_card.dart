import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../design_system/design_system.dart';
import '../../application/bookmarks_controller.dart';
import '../../domain/job.dart';
import '../util/job_labels.dart';

/// Job summary card used across Home, See-all, Bookmarks and Search. Tapping
/// opens details; the bookmark toggle is wired to [bookmarksControllerProvider].
/// Pass [width] to use it inside a horizontal carousel.
class JobCard extends ConsumerWidget {
  const JobCard({super.key, required this.job, this.width});

  final Job job;
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final bookmarked =
        ref.watch(bookmarksControllerProvider).value?.contains(job.id) ?? false;
    final subtitle = [
      job.companyName,
      if (job.locationText.isNotEmpty) job.locationText,
    ].join(' • ');
    final tags = [
      ?jobTypeLabel(context, job.jobType),
      ?workingModelLabel(context, job.workingModel),
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
              children: [
                _Logo(url: job.companyLogoUrl),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: context.text.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: context.text.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                InkResponse(
                  onTap: () => ref
                      .read(bookmarksControllerProvider.notifier)
                      .toggle(job.id),
                  child: Icon(
                    bookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: bookmarked ? colors.primary : colors.textSecondary,
                  ),
                ),
              ],
            ),
            if (job.salaryText != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                job.salaryText!,
                style: context.text.labelLarge?.copyWith(color: colors.primary),
              ),
            ],
            if (tags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [for (final t in tags) _Tag(t)],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fallback = Icon(
      Icons.business_rounded,
      color: colors.primary,
      size: 22,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        height: 44,
        width: 44,
        color: colors.chipBackground,
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
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.chipBackground,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(color: colors.textPrimary),
      ),
    );
  }
}
