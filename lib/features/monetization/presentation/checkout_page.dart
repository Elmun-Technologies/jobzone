import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/options/option_lists.dart';
import '../data/monetization_repository.dart';
import '../domain/promotion.dart';

/// Self-serve checkout for a promotion tariff. The plan and its price are shown
/// in full (tariffs stay), but the actual payment (Click / Payme) is still
/// being connected — there is no wallet and no fake charge here. Once the
/// gateway is live this screen gains the real pay action.
class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({
    super.key,
    required this.jobId,
    required this.productCode,
  });

  final String jobId;
  final String productCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final colors = context.colors;
    final productsAsync = ref.watch(promotionProductsProvider);

    return Scaffold(
      body: SafeArea(
        child: productsAsync.when(
          loading: () => const JzLoader(),
          error: (_, _) => JzErrorState(
            title: l.errorTitle,
            message: l.errUnknown,
            retryLabel: l.retry,
            onRetry: () => ref.invalidate(promotionProductsProvider),
          ),
          data: (products) {
            final product = products
                .where((p) => p.code == productCode)
                .firstOrNull;
            if (product == null) {
              return JzErrorState(
                title: l.errorTitle,
                message: l.errUnknown,
                retryLabel: l.retry,
                onRetry: () => context.pop(),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: JzTopBar(title: l.checkoutTitle),
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
                      _SummaryCard(product: product),
                      const SizedBox(height: AppSpacing.lg),
                      const _PaymentSoonNotice(),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l.offerNote,
                        style: context.text.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.toPayLabel,
                                style: context.text.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                              Text(
                                formatUzs(product.priceUzs),
                                style: context.text.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // No wallet/instant charge — the pay action is disabled
                        // until the Click/Payme gateway is connected.
                        Expanded(
                          child: JzPrimaryButton(
                            label: l.comingSoon,
                            onPressed: null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Honest placeholder for the payment step while Click / Payme is being wired.
class _PaymentSoonNotice extends StatelessWidget {
  const _PaymentSoonNotice();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.credit_card_rounded, size: 18, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.comingSoon,
                  style: context.text.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  l.checkoutPaymentSoon,
                  style: context.text.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.product});
  final PromotionProduct product;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
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
          Text(
            promotionName(l, product.code, fallback: product.name),
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (promotionDesc(l, product.code) ?? product.description
              case final desc?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              desc,
              style: context.text.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            formatUzs(product.priceUzs),
            style: context.text.titleLarge?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Line(icon: Icons.bolt_rounded, text: l.activatesAfterPayment),
          if (product.durationDays != null)
            _Line(
              icon: Icons.schedule_rounded,
              text: l.validForDays(product.durationDays!),
            ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: context.text.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
