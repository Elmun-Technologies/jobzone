import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/options/option_lists.dart';
import '../data/monetization_repository.dart';
import '../domain/promotion.dart';

/// Employer view of their promotion purchases (orders + status).
class PromotionsHistoryPage extends ConsumerWidget {
  const PromotionsHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ordersAsync = ref.watch(myOrdersProvider);
    final products = ref.watch(promotionProductsProvider).value ?? const [];
    final nameByCode = {for (final p in products) p.code: p.name};

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.promotionsTitle),
            ),
            Expanded(
              child: ordersAsync.when(
                loading: () => const JzLoader(),
                error: (_, _) => JzErrorState(
                  title: l.errorTitle,
                  message: l.errUnknown,
                  retryLabel: l.retry,
                  onRetry: () => ref.invalidate(myOrdersProvider),
                ),
                data: (orders) {
                  if (orders.isEmpty) {
                    return JzEmptyState(
                      icon: Icons.bolt_rounded,
                      title: l.noPromotionsTitle,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) => _OrderRow(
                      order: orders[i],
                      productName: promotionName(
                        l,
                        orders[i].productCode,
                        fallback:
                            nameByCode[orders[i].productCode] ??
                            orders[i].productCode,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.productName});
  final PromotionOrder order;
  final String productName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final date = order.createdAt;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.chipBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.bolt_rounded, color: colors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  dateStr,
                  style: context.text.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatUzs(order.amountUzs),
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              _StatusChip(status: order.status),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final (label, color) = switch (status) {
      'paid' => (l.orderStatusPaid, const Color(0xFF16A34A)),
      'cancelled' => (l.orderStatusCancelled, colors.textSecondary),
      'refunded' => (l.orderStatusRefunded, const Color(0xFFDB2777)),
      _ => (l.orderStatusPending, const Color(0xFFF59E0B)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
