import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../jobs/presentation/widgets/job_card.dart';
import '../application/search_controller.dart';

/// Map-style Explore screen. A real map (google_maps_flutter) drops in where
/// `_MapBackdrop` is; until then it renders a neutral map placeholder with job
/// pins, matching the Figma layout (floating search + filter, current-location
/// button, and a bottom job carousel).
class ExplorePage extends ConsumerWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final colors = context.colors;
    final results = ref.watch(searchControllerProvider);
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _MapBackdrop()),
          Positioned(
            top: topPad + AppSpacing.sm,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push(Routes.search),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            l.search,
                            style: context.text.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                GestureDetector(
                  onTap: () => context.push(Routes.filter),
                  child: Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC629),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: AppSpacing.lg,
            bottom: 250,
            child: _CircleFab(
              icon: Icons.my_location_rounded,
              onTap: () => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(l.comingSoon))),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.lg,
            child: SizedBox(
              height: 210,
              child: results.maybeWhen(
                data: (jobs) => jobs.isEmpty
                    ? const SizedBox.shrink()
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        itemCount: jobs.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.md),
                        itemBuilder: (_, i) => SizedBox(
                          width: MediaQuery.sizeOf(context).width * 0.82,
                          child: JobCard(job: jobs[i]),
                        ),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapBackdrop extends StatelessWidget {
  const _MapBackdrop();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: const Color(0xFFE9EBF0),
      child: Stack(
        children: [
          // Faux "region" highlight.
          Align(
            alignment: const Alignment(0, -0.1),
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(140),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          for (final a in const [
            Alignment(-0.5, -0.4),
            Alignment(0.45, -0.55),
            Alignment(0.3, 0.05),
            Alignment(-0.35, 0.2),
          ])
            Align(
              alignment: a,
              child: Icon(
                Icons.location_on_rounded,
                color: colors.primary,
                size: 28,
              ),
            ),
          // Selected pin (center).
          Align(
            alignment: const Alignment(0, -0.1),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleFab extends StatelessWidget {
  const _CircleFab({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: colors.primary),
        ),
      ),
    );
  }
}
