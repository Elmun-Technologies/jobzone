import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../search/domain/job_collection.dart';
import '../../../search/presentation/job_collection_label.dart';

/// Horizontal row of apna-style "quick find" cards. Tapping one opens a
/// pre-filtered results list ([CollectionResultsPage]) so seekers reach the
/// right jobs in one tap instead of configuring filters.
class JobCollectionsRow extends StatelessWidget {
  const JobCollectionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: JobCollection.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) {
          final c = JobCollection.values[i];
          return _CollectionCard(
            collection: c,
            onTap: () => context.push(Routes.collection(c.key)),
          );
        },
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.collection, required this.onTap});

  final JobCollection collection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = collection.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 108,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(collection.icon, color: accent, size: 22),
            ),
            const Spacer(),
            Text(
              collection.label(context),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
