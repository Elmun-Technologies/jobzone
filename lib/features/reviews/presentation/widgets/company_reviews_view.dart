import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../data/reviews_repository.dart';
import '../../domain/review.dart';
import 'star_rating_input.dart';

/// Reviews list for a company with an average-rating header and a
/// "write a review" entry point. Shared by the Job Details and Company
/// Details review tabs.
class CompanyReviewsView extends ConsumerWidget {
  const CompanyReviewsView({
    super.key,
    required this.companyId,
    this.companyName,
  });

  final String companyId;
  final String? companyName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(companyReviewsProvider(companyId));

    void openWrite() =>
        context.push(Routes.writeCompanyReview(companyId), extra: companyName);

    return async.when(
      loading: () => const JzLoader(),
      error: (_, _) => JzErrorState(
        title: l.errorTitle,
        message: l.errUnknown,
        retryLabel: l.retry,
        onRetry: () => ref.invalidate(companyReviewsProvider(companyId)),
      ),
      data: (reviews) {
        if (reviews.isEmpty) {
          return Column(
            children: [
              Expanded(
                child: JzEmptyState(
                  icon: Icons.reviews_outlined,
                  title: l.reviewsEmptyTitle,
                  message: l.reviewsEmptyBody,
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: OutlinedButton.icon(
                    onPressed: openWrite,
                    icon: const Icon(Icons.rate_review_outlined),
                    label: Text(l.writeAReview),
                  ),
                ),
              ),
            ],
          );
        }
        final avg =
            reviews.map((r) => r.rating).reduce((a, b) => a + b) /
            reviews.length;
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: reviews.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (c, i) {
            if (i == 0) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        avg.toStringAsFixed(1),
                        style: context.text.headlineSmall,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StarRatingDisplay(rating: avg),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: openWrite,
                    icon: const Icon(Icons.rate_review_outlined, size: 18),
                    label: Text(l.writeAReview),
                  ),
                ],
              );
            }
            return ReviewCard(review: reviews[i - 1]);
          },
        );
      },
    );
  }
}

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});
  final CompanyReview review;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StarRatingDisplay(rating: review.rating.toDouble()),
              const Spacer(),
              if (review.authorName != null)
                Text(
                  review.authorName!,
                  style: context.text.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
            ],
          ),
          if (review.title != null && review.title!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(review.title!, style: context.text.titleSmall),
          ],
          if (review.body != null && review.body!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              review.body!,
              style: context.text.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          if ((review.pros != null && review.pros!.isNotEmpty) ||
              (review.cons != null && review.cons!.isNotEmpty)) ...[
            const SizedBox(height: AppSpacing.sm),
            if (review.pros != null && review.pros!.isNotEmpty)
              _ProsCons(
                icon: Icons.add_circle_outline_rounded,
                color: colors.success,
                text: review.pros!,
              ),
            if (review.cons != null && review.cons!.isNotEmpty)
              _ProsCons(
                icon: Icons.remove_circle_outline_rounded,
                color: colors.danger,
                text: review.cons!,
              ),
          ],
        ],
      ),
    );
  }
}

class _ProsCons extends StatelessWidget {
  const _ProsCons({
    required this.icon,
    required this.color,
    required this.text,
  });
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
