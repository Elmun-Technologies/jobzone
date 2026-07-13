import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../domain/listing_tier.dart';
import '../domain/promotion.dart' show formatUzs;

/// Employer per-listing visibility tiers (Standart / Brend / Premium), priced
/// per vacancy — the first vacancy is free, from the 2nd onward one of these.
/// The web mirror is the `/pricing` page and the `/about` pricing section; the
/// numbers live in `domain/listing_tier.dart`. Informational for now — the
/// post-time picker + charge is wired separately.
class TiersPage extends StatelessWidget {
  const TiersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.tiersTitle),
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
                  Text(
                    l.tiersSubtitle,
                    style: context.text.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: colors.chipBackground,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l.tiersFirstFree,
                            style: context.text.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (final info in kListingTiers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _TierCard(info: info),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l.tiersNote,
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
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

class _TierCard extends StatelessWidget {
  const _TierCard({required this.info});
  final ListingTierInfo info;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final t = info.tier;
    final emphasized = info.featured || info.isPremium;

    final name = switch (t) {
      ListingTier.standard => l.tierStandardName,
      ListingTier.brand => l.tierBrandName,
      ListingTier.premium => l.tierPremiumName,
    };
    final tagline = switch (t) {
      ListingTier.standard => l.tierStandardTagline,
      ListingTier.brand => l.tierBrandTagline,
      ListingTier.premium => l.tierPremiumTagline,
    };
    final bullets = switch (t) {
      ListingTier.standard => [
        l.tierStandardF1,
        l.tierStandardF2,
        l.tierStandardF3,
      ],
      ListingTier.brand => [l.tierBrandF1, l.tierBrandF2, l.tierBrandF3],
      ListingTier.premium => [
        l.tierPremiumF1,
        l.tierPremiumF2,
        l.tierPremiumF3,
      ],
    };
    final angle = switch (t) {
      ListingTier.standard => l.tierStandardAngle,
      ListingTier.brand => l.tierBrandAngle,
      ListingTier.premium => l.tierPremiumAngle,
    };
    final badge = switch (t) {
      ListingTier.standard => null,
      ListingTier.brand => l.tierPopular,
      ListingTier.premium => l.tierBestResult,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: info.isPremium
            ? colors.primary.withValues(alpha: 0.08)
            : (info.featured ? colors.chipBackground : colors.surface),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: emphasized ? colors.primary : colors.border,
          width: emphasized ? 1.8 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: context.text.labelSmall?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            tagline,
            style: context.text.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            formatUzs(info.priceUzs),
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final b in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_rounded, size: 16, color: colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(b, style: context.text.bodyMedium)),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: emphasized
                  ? colors.primary.withValues(alpha: 0.15)
                  : colors.chipBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              angle,
              style: context.text.bodySmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
