import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../../monetization/domain/promotion.dart' show formatUzs;
import '../../data/wallet_repository.dart';
import '../../domain/wallet.dart';

/// "dd.MM.yyyy" — locale-agnostic and stable, matching the web wallet page.
String _formatDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd.$mm.${d.year}';
}

const _presets = [50000, 100000, 200000, 500000];

/// Hamyon: balance, top-up (record-only until the payment gateway is wired —
/// same pending-until-confirmed shape as the web wallet page), and the recent
/// ledger. Mirrors `webapp/src/app/[locale]/employer/wallet/page.tsx`.
class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  final _amountController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitTopUp() async {
    final l = context.l10n;
    final digits = _amountController.text.replaceAll(RegExp(r'\D'), '');
    final amount = num.tryParse(digits);
    if (amount == null || amount < 1000) {
      showErrorSnack(context, l.walletErrAmount);
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(walletRepositoryProvider).requestTopUp(amount);
      ref.invalidate(walletProvider);
      if (!mounted) return;
      _amountController.clear();
      showInfoSnack(context, l.walletTopUpPending);
    } catch (e) {
      if (mounted) showErrorSnack(context, localizedError(context, e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final async = ref.watch(walletProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              JzTopBar(title: l.walletTitle),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: async.when(
                  loading: () => const JzLoader(),
                  error: (_, _) => JzErrorState(
                    title: l.errorTitle,
                    message: l.errUnknown,
                    retryLabel: l.retry,
                    onRetry: () => ref.invalidate(walletProvider),
                  ),
                  data: (wallet) => RefreshIndicator(
                    onRefresh: () async => ref.invalidate(walletProvider),
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      children: [
                        _BalanceCard(wallet: wallet),
                        const SizedBox(height: AppSpacing.lg),
                        _TopUpCard(
                          controller: _amountController,
                          submitting: _submitting,
                          onSubmit: _submitTopUp,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          l.walletHistory,
                          style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (wallet.transactions.isEmpty)
                          JzEmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: l.walletHistoryEmpty,
                          )
                        else
                          for (final tx in wallet.transactions)
                            _TransactionRow(tx: tx),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The balance shown as a branded "bank card": a fixed ink surface (so it reads
/// the same in light and dark) with a volt wallet chip, a decorative volt disc,
/// and the amount in large white type. Gives the wallet a confident centrepiece
/// instead of a plain grey box.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.wallet});
  final Wallet wallet;

  static const _ink = Color(0xFF0F0F0F);
  static const _inkTop = Color(0xFF1C1C1C);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_inkTop, _ink],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Decorative volt disc bleeding off the top-right corner.
          Positioned(
            right: -34,
            top: -34,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: 0.16),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 20,
                      color: colors.onPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l.walletTitle,
                    style: context.text.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l.walletBalanceLabel,
                style: context.text.bodySmall?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: AppSpacing.xs),
              // Scale down rather than overflow when the balance is large
              // (e.g. "100 000 000 so'm").
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatUzs(wallet.balanceUzs),
                  maxLines: 1,
                  style: context.text.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.walletBalanceHint,
                style: context.text.bodySmall?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopUpCard extends StatelessWidget {
  const _TopUpCard({
    required this.controller,
    required this.submitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onSubmit;

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
            l.walletTopUp,
            style: context.text.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.walletTopUpSub,
            style: context.text.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final p in _presets)
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    final selected = value.text == p.toString();
                    return ChoiceChip(
                      label: Text(formatUzs(p)),
                      selected: selected,
                      onSelected: (_) => controller.text = p.toString(),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(hintText: l.walletAmountHint),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              JzPrimaryButton(
                label: l.walletTopUp,
                loading: submitting,
                onPressed: onSubmit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.tx});
  final WalletTransaction tx;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final kindLabel = switch (tx.kind) {
      'topup' => l.walletKindTopup,
      'spend' => l.walletKindSpend,
      'refund' => l.walletKindRefund,
      'bonus' => l.walletKindBonus,
      _ => tx.kind,
    };
    final meta = tx.isPending
        ? '${_formatDate(tx.createdAt)} · ${l.walletStatusPending}'
        : _formatDate(tx.createdAt);
    final amountColor = tx.isPending
        ? colors.textSecondary
        : (tx.isCredit ? colors.success : colors.textPrimary);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tx.isCredit
                  ? colors.success.withValues(alpha: 0.12)
                  : colors.chipBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              tx.isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 18,
              color: tx.isCredit ? colors.success : colors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description ?? kindLabel,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  meta,
                  style: context.text.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${tx.isCredit ? '+' : '−'}${formatUzs(tx.amountUzs.abs())}',
            style: context.text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
