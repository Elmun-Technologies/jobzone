import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../domain/promotion.dart';

/// A selectable promotion package card (gamified). Gold accent for TOP tiers,
/// disabled/"coming soon" for AI screening.
class PromoPackageCard extends StatelessWidget {
  const PromoPackageCard({
    super.key,
    required this.product,
    required this.selected,
    required this.onTap,
  });

  final PromotionProduct product;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final disabled = product.isComingSoon;
    final accent = product.isTop ? colors.gold : colors.primary;

    final priceText = product.isComingSoon
        ? l.comingSoon
        : (product.isFree ? l.freeLabel : formatUzs(product.priceUzs));

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: disabled ? null : onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selected ? accent : colors.border,
                width: selected ? 1.8 : 1,
              ),
            ),
            child: Row(
              children: [
                if (product.isTop)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: Icon(Icons.bolt_rounded, color: colors.gold),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (product.description != null)
                        Text(
                          product.description!,
                          style: context.text.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      priceText,
                      style: context.text.titleSmall?.copyWith(
                        color: product.isFree ? colors.textSecondary : accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (selected)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: accent,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
