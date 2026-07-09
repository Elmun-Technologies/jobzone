import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/widgets/snackbars.dart';
import '../../employer/data/employer_jobs_repository.dart';
import '../../employer/data/wallet_repository.dart';
import '../data/monetization_repository.dart';
import '../domain/promotion.dart';

/// Self-serve checkout for a promotion tariff, paid from the employer's
/// Hamyon balance: an order summary + the current balance, then either
/// "Confirm & pay" (enough funds — spends immediately, both offline and live)
/// or "Top up Hamyon" (not enough — sends them to add funds first, same as
/// the web promote page).
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
  bool _paying = false;

  Future<void> _pay() async {
    setState(() => _paying = true);
    try {
      final order = await ref
          .read(monetizationRepositoryProvider)
          .purchase(jobId: widget.jobId, productCode: widget.productCode);
      ref.invalidate(myJobsProvider);
      ref.invalidate(myOrdersProvider);
      ref.invalidate(walletProvider);
      if (!mounted) return;
      showInfoSnack(
        context,
        order.isPaid
            ? context.l10n.promotedToast
            : context.l10n.orderPendingToast,
      );
      context.pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, localizedError(context, e));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final productsAsync = ref.watch(promotionProductsProvider);
    final walletAsync = ref.watch(walletProvider);

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
            final balance = walletAsync.value?.balanceUzs;
            final affordable = balance != null && balance >= product.priceUzs;

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
                      _BalanceRow(balanceUzs: balance),
                      if (balance != null && !affordable) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _InsufficientFundsNotice(needed: product.priceUzs),
                      ],
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
                        Expanded(
                          // While the wallet is still loading, balance is null;
                          // show a loading Pay button rather than flashing the
                          // wrong "Top up" CTA to someone who can afford it.
                          child: walletAsync.isLoading && balance == null
                              ? const JzPrimaryButton(
                                  label: '',
                                  loading: true,
                                  onPressed: null,
                                )
                              : affordable
                              ? JzPrimaryButton(
                                  label: l.payCta,
                                  loading: _paying,
                                  onPressed: _pay,
                                )
                              : JzPrimaryButton(
                                  label: l.topUpWalletCta,
                                  onPressed: () =>
                                      context.push(Routes.employerWallet),
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

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.balanceUzs});
  final num? balanceUzs;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l.walletBalanceLabel,
            style: context.text.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          balanceUzs == null
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  formatUzs(balanceUzs!),
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ],
      ),
    );
  }
}

class _InsufficientFundsNotice extends StatelessWidget {
  const _InsufficientFundsNotice({required this.needed});
  final num needed;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: colors.gold),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.insufficientFundsTitle,
                  style: context.text.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  l.insufficientFundsHint(formatUzs(needed)),
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
            product.name,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (product.description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              product.description!,
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
