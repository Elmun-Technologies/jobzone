import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';

/// Wraps a subtree of [SkeletonBox]es and sweeps an animated shimmer highlight
/// across them. Lightweight (no package): a translating gradient painted over
/// the opaque boxes via [BlendMode.srcATop].
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});
  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = colors.surfaceVariant;
    final highlight = Color.lerp(base, colors.surface, 0.7) ?? base;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            // Slide a [base, highlight, base] gradient left → right.
            final slide = -1.0 + 3.0 * _controller.value;
            return LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlideTransform(slide),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class _SlideTransform extends GradientTransform {
  const _SlideTransform(this.slide);
  final double slide;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * slide, 0, 0);
}

/// A single placeholder block. Place inside a [Shimmer] to animate.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppRadius.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Placeholder that mimics a `JobCard` while jobs load.
class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key, this.width});
  final double? width;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
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
              const SkeletonBox(width: 44, height: 44, radius: AppRadius.sm),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(height: 12),
                    SizedBox(height: AppSpacing.xs),
                    SkeletonBox(width: 120, height: 10),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const SkeletonBox(width: 90, height: 12),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: const [
              SkeletonBox(width: 64, height: 22, radius: AppRadius.pill),
              SizedBox(width: AppSpacing.sm),
              SkeletonBox(width: 64, height: 22, radius: AppRadius.pill),
            ],
          ),
        ],
      ),
    );
  }
}

/// Placeholder for a leading-avatar list row (chat list, notifications).
class ListTileSkeleton extends StatelessWidget {
  const ListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 48, height: 48, radius: AppRadius.pill),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 140, height: 12),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A shimmering column of [ListTileSkeleton]s for avatar-list loading states.
class TileListSkeleton extends StatelessWidget {
  const TileListSkeleton({super.key, this.count = 6});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        children: [for (var i = 0; i < count; i++) const ListTileSkeleton()],
      ),
    );
  }
}

/// A shimmering column of [JobCardSkeleton]s for list loading states.
class JobListSkeleton extends StatelessWidget {
  const JobListSkeleton({super.key, this.count = 4, this.padding});
  final int count;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        // shrinkWrap so it renders inside unbounded parents (e.g. a Column or
        // scroll view on the Home / Search loading state) without throwing an
        // "unbounded height" RenderFlex error.
        shrinkWrap: true,
        padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
        itemCount: count,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, _) => const JobCardSkeleton(),
      ),
    );
  }
}
