import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/widgets/snackbars.dart';
import '../../employer/data/employer_jobs_repository.dart';
import '../data/monetization_repository.dart';
import '../domain/promotion.dart';

/// hh-style checkout for a promotion tariff: an order summary + payment-method
/// choice, then creates the order. Offline the boost is applied immediately;
/// live the order is created `pending` until the Click/Payme webhook
/// (`payment-webhook` edge fn) flips it to paid. The gateway redirect plugs in
/// here once merchant credentials exist.
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
  String _method = 'card';
  bool _paying = false;

  Future<void> _pay() async {
    setState(() => _paying = true);
    try {
      final order = await ref
          .read(monetizationRepositoryProvider)
          .purchase(jobId: widget.jobId, productCode: widget.productCode);
      ref.invalidate(myJobsProvider);
      ref.invalidate(myOrdersProvider);
      if (!mounted) return;
      showInfoSnack(
        context,
        order.isPaid
            ? context.l10n.promotedToast
            : context.l10n.orderPendingToast,
      );
      context.pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final async = ref.watch(promotionProductsProvider);

    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const JzLoader(),
          error: (_, _) => Center(child: Text(l.errUnknown)),
          data: (products) {
            final product = products.firstWhere(
              (p) => p.code == widget.productCode,
              orElse: () => products.first,
            );
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
                      Text(l.paymentMethod, style: context.text.labelLarge),
                      const SizedBox(height: AppSpacing.sm),
                      _MethodTile(
                        icon: Icons.credit_card_rounded,
                        title: l.payMethodCard,
                        subtitle: l.payMethodCardHint,
                        selected: _method == 'card',
                        onTap: () => setState(() => _method = 'card'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _MethodTile(
                        icon: Icons.receipt_long_rounded,
                        title: l.payMethodInvoice,
                        subtitle: l.payMethodInvoiceHint,
                        selected: _method == 'invoice',
                        onTap: () => setState(() => _method = 'invoice'),
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
                        Expanded(
                          child: JzPrimaryButton(
                            label: l.payCta,
                            loading: _paying,
                            onPressed: _pay,
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

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: context.text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            JzRadio(selected: selected),
          ],
        ),
      ),
    );
  }
}
