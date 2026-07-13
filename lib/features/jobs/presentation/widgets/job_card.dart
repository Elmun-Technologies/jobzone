import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../application/bookmarks_controller.dart';
import '../../application/dismissed_controller.dart';
import '../../domain/job.dart';
import '../util/job_labels.dart';
import 'bookmark_confirm_sheet.dart';
import 'quick_apply_button.dart';

/// Job summary card used across Home, See-all, Bookmarks and Search. Tapping
/// opens details (with an ink ripple); the top strip carries the bookmark and
/// archive toggles (animated); the footer pairs the salary — the number a
/// seeker decides on — with a one-tap [QuickApplyButton] "⚡ Apply" pill.
/// Pass [width] to use it inside a horizontal carousel.
class JobCard extends ConsumerWidget {
  const JobCard({super.key, required this.job, this.width});

  final Job job;
  final double? width;

  /// The listing-tier badge shown top-left: a gold "Premium"/"TOP" pill for a
  /// standout tier, a volt-outline "Brend" tag for the logo-glow tier (where the
  /// glowing logo is the main signal), or nothing for a plain listing.
  Widget? _tierBadge(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    if (job.tierStandout) {
      return JzTopBadge(
        label: job.boostKind == 'premium' ? l.tierPremiumName : 'TOP',
      );
    }
    if (job.tierGlowLogo) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: colors.primary, width: 1.4),
        ),
        child: Text(
          l.tierBrandName,
          style: context.text.labelSmall?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final colors = context.colors;
    final bookmarked =
        ref.watch(bookmarksControllerProvider).value?.contains(job.id) ?? false;
    final dismissed =
        ref.watch(dismissedControllerProvider).value?.contains(job.id) ?? false;

    // Location + working conditions collapse into one dotted meta line — the
    // old separate location row + three-chip Wrap could run to two lines and
    // stretch the card.
    final meta = <String>[
      if (job.locationText.isNotEmpty) job.locationText,
      ?jobTypeLabel(context, job.jobType),
      ?workingModelLabel(context, job.workingModel),
      ?experienceLabel(context, job.experienceLevel),
    ];

    // JzPressable: the whole card eases down slightly while pressed — tactile
    // feedback on the app's most-tapped surface (raw Listener, so it never
    // steals the InkWell's tap or the toggles' taps).
    final tierBadge = _tierBadge(context);
    return JzPressable(
      child: Container(
        width: width,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: job.tierStandout ? colors.primary : colors.border,
            width: job.tierStandout ? 1.6 : 1,
          ),
          // A soft lift so the card reads as tappable (no-op in dark, where the
          // border carries separation instead); a Premium standout listing gets
          // a volt glow so it visibly pops off the feed.
          boxShadow: [
            job.tierStandout
                ? BoxShadow(
                    color: colors.primary.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  )
                : BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(Routes.jobDetails(job.id)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      ?tierBadge,
                      const Spacer(),
                      _IconToggle(
                        active: bookmarked,
                        activeIcon: Icons.bookmark_rounded,
                        inactiveIcon: Icons.bookmark_border_rounded,
                        activeColor: colors.primary,
                        semanticLabel: bookmarked
                            ? l.removeBookmark
                            : l.addBookmark,
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
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _IconToggle(
                        active: dismissed,
                        activeIcon: Icons.archive_rounded,
                        inactiveIcon: Icons.archive_outlined,
                        activeColor: colors.primary,
                        size: 20,
                        semanticLabel: dismissed
                            ? l.jobDismissed
                            : l.dismissJob,
                        onTap: () => ref
                            .read(dismissedControllerProvider.notifier)
                            .toggle(job.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      _Logo(
                        name: job.companyName,
                        url: job.companyLogoUrl,
                        glow: job.tierGlowLogo,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.title,
                              style: context.text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
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
                                  const JzTrustBadge(
                                    kind: JzTrustKind.employer,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _MetaLine(parts: meta),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Divider(color: colors.border, height: 1),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: _Salary(job: job)),
                      const SizedBox(width: AppSpacing.sm),
                      QuickApplyButton(job: job, pill: true),
                    ],
                  ),
                  if (job.applicantsCount > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${job.applicantsCount} ${l.applicants}',
                      style: context.text.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal, equal-height row of [JobCard]s for the Home strips.
///
/// Uses `IntrinsicHeight` so the row is exactly as tall as its tallest card and
/// every card stretches to match — the old fixed-height (`SizedBox(height:220)`
/// + horizontal `ListView`) clipped boosted / two-line-tag cards, producing the
/// "RenderFlex overflowed" stripes. Meant for short lists (suggested /
/// recommended); it builds all children eagerly, so it is not used for the
/// potentially-long Explore result carousel.
class JobCardCarousel extends StatelessWidget {
  const JobCardCarousel({
    super.key,
    required this.jobs,
    this.cardWidth = 300,
    this.padding,
  });

  final List<Job> jobs;
  final double cardWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < jobs.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.md),
              // Staggered entrance (capped so late cards don't lag behind).
              JzFadeSlideIn(
                delay: Duration(milliseconds: 70 * (i < 5 ? i : 5)),
                dy: 12,
                child: SizedBox(
                  width: cardWidth,
                  child: JobCard(job: jobs[i]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Salary (the number a seeker decides on) shown large and bold, with the pay
/// period as a lighter suffix. Scales down instead of clipping in narrow cards.
class _Salary extends StatelessWidget {
  const _Salary({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final salary = job.salaryText;
    if (salary == null || salary.isEmpty) return const SizedBox.shrink();
    final period = salaryPeriodLabel(context, job.salaryPeriod);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: RichText(
        maxLines: 1,
        text: TextSpan(
          text: salary,
          style: context.text.titleMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
          children: [
            if (period != null)
              TextSpan(
                text: ' $period',
                style: context.text.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A dotted, single-run meta line: "Location · Full-time · Experience". Wraps
/// gracefully rather than overflowing.
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.parts});
  final List<String> parts;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.text.bodySmall?.copyWith(color: colors.textSecondary);
    final children = <Widget>[];
    for (var i = 0; i < parts.length; i++) {
      if (i > 0) {
        children.add(
          Container(
            width: 3,
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
        );
      }
      children.add(Text(parts[i], style: style));
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

/// A small, animated toggle icon (bookmark / archive) with a comfortable tap
/// target. The icon pops with a scale when its state flips.
class _IconToggle extends StatelessWidget {
  const _IconToggle({
    required this.active,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.activeColor,
    required this.semanticLabel,
    required this.onTap,
    this.size = 24,
  });

  final bool active;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final Color activeColor;
  final String semanticLabel;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutBack,
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              active ? activeIcon : inactiveIcon,
              key: ValueKey(active),
              size: size,
              color: active ? activeColor : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.name, this.url, this.glow = false});
  final String name;
  final String? url;

  /// Brand/Premium listings light the logo up with a volt ring + glow.
  final bool glow;

  static const _palette = [
    Color(0xFF0A0A0A),
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
    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        height: 52,
        width: 52,
        child: (url == null || url!.isEmpty)
            ? fallback
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => fallback,
              ),
      ),
    );
    if (!glow) return logo;
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
        border: Border.all(color: colors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: logo,
    );
  }
}
