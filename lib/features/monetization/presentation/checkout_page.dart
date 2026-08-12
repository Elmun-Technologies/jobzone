import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/options/option_lists.dart';
import '../../../shared/widgets/snackbars.dart';
import '../../employer/data/employer_jobs_repository.dart';
import '../../employer/data/wallet_repository.dart';
import '../data/monetization_repository.dart';
import '../domain/promotion.dart';

/// Self-serve checkout for a promotion tariff: pay for the boost out of the
/// Hamyon balance.
///
/// `buy_promotion` (0043) is one atomic step server-side — debit the wallet,
/// extend the job's boost, record the paid order — so there is no half-charged
/// state to recover from here. When the balance is short we don't fail: the
/// screen says how much is missing and sends the employer to the wallet with
/// that amount already filled in, where the gateway tops it up for real (0085).
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({
    super.key,
    required this.jobId,
    required this.productCode,
  });

  final String jobId;
  final String productCode;

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  bool _busy = false;

  /// Spends the balance on the boost, then refreshes everything the purchase
  /// moved: the wallet, the order history and the employer's job list (whose
  /// cards show the boost badge).
  Future<void> _payFromWallet(PromotionProduct product) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(monetizationRepositoryProvider)
          .purchase(jobId: widget.jobId, productCode: widget.productCode);
      ref.invalidate(walletProvider);
      ref.invalidate(myOrdersProvider);
      ref.invalidate(myJobsProvider);
      if (!mounted) return;
      showInfoSnack(context, context.l10n.checkoutPaid);
      context.pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, localizedError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final productsAsync = ref.watch(promotionProductsProvider);
    final balance = ref.watch(walletProvider).value?.balanceUzs ?? 0;

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
                .where((p) => p.code == widget.productCode)
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
                      _BalanceNotice(
                        balanceUzs: balance,
                        priceUzs: product.priceUzs,
                      ),
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
                        // Enough balance → charge it. Short → the same button
                        // becomes the way to fix that, carrying the shortfall.
                        Expanded(
                          child: balance >= product.priceUzs
                              ? JzPrimaryButton(
                                  label: l.checkoutPayFromWallet,
                                  loading: _busy,
                                  onPressed: _busy
                                      ? null
                                      : () => _payFromWallet(product),
                                )
                              : JzPrimaryButton(
                                  label: l.topUpWalletCta,
                                  onPressed: () => context.push(
                                    Routes.employerWallet,
                                    extra: (product.priceUzs - balance).ceil(),
                                  ),
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

/// What the purchase will cost against what the wallet holds — and, when that
/// isn't enough, exactly how much is missing (guessing is the employer's job
/// otherwise).
class _BalanceNotice extends StatelessWidget {
  const _BalanceNotice({required this.balanceUzs, required this.priceUzs});

  final num balanceUzs;
  final num priceUzs;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final enough = balanceUzs >= priceUzs;
    final accent = enough ? colors.primary : colors.warning;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            enough
                ? Icons.account_balance_wallet_rounded
                : Icons.error_outline_rounded,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l.walletBalanceLabel}: ${formatUzs(balanceUzs)}',
                  style: context.text.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  enough ? l.activatesAfterPayment : l.walletInsufficient,
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
