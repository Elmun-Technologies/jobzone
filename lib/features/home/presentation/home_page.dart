import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.greeting,
                        style: context.text.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      Text(l.findNextJob, style: context.text.titleLarge),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => context.push(Routes.notifications),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _SearchBar(
              hint: l.search,
              onTap: () => context.push(Routes.search),
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: l.suggestedJobs,
              actionLabel: l.seeAll,
              onAction: () => context.push(Routes.suggestedJobs),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 172,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (_, i) => const _SuggestedCard(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: l.recentJobs,
              actionLabel: l.seeAll,
              onAction: () => context.push(Routes.recentJobs),
            ),
            const SizedBox(height: AppSpacing.md),
            ...List.generate(
              4,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: _RecentTile(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.hint, required this.onTap});
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: colors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              hint,
              style: context.text.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, this.width});
  final Widget child;
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
      child: child,
    );
  }
}

class _JobLogo extends StatelessWidget {
  const _JobLogo();
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: colors.chipBackground,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(Icons.business_rounded, color: colors.primary, size: 22),
    );
  }
}

class _SuggestedCard extends StatelessWidget {
  const _SuggestedCard();
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _CardShell(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const _JobLogo(),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Designer',
                      style: context.text.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Acme • Remote',
                      style: context.text.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            r'$80k – $120k / yr',
            style: context.text.labelLarge?.copyWith(color: colors.primary),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            children: const [
              Chip(label: Text('Full-time')),
              Chip(label: Text('Senior')),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile();
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _CardShell(
      child: Row(
        children: [
          const _JobLogo(),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Senior Flutter Engineer',
                  style: context.text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Acme • Tashkent',
                  style: context.text.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.bookmark_border_rounded, color: colors.textSecondary),
        ],
      ),
    );
  }
}
