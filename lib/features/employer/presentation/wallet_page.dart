import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/env.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/widgets/snackbars.dart';
import '../../monetization/domain/checkout_url.dart';
import '../../monetization/domain/promotion.dart' show formatUzs;
import '../data/employer_jobs_repository.dart';
import '../data/wallet_repository.dart';
import '../domain/wallet.dart';

/// Hamyon — the employer's wallet: balance, top-up, and the ledger.
///
/// Top-up is a real charge, not a request form: `create_topup_order` (0085)
/// opens the pending credit, the chosen gateway's checkout is opened in the
/// system browser, and the provider's callback completes the row — the same
/// rails the pay-per-vacancy screen uses, addressing the top-up by the same
/// `order_id`. While the payer is at the gateway we poll the balance, so
/// coming back to the app shows the money already there.
class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key, this.initialAmount});

  /// Pre-fills the amount — the promote screen passes the shortfall so the
  /// employer doesn't have to work out how much they need.
  final int? initialAmount;

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  static const _presets = [50000, 100000, 200000, 500000];
  static const _minTopUp = 5000;

  late final TextEditingController _amount = TextEditingController(
    text: widget.initialAmount?.toString() ?? '',
  );
  bool _busy = false;
  bool _awaiting = false;
  num? _balanceBefore;
  Timer? _poll;

  @override
  void dispose() {
    _poll?.cancel();
    _amount.dispose();
    super.dispose();
  }

  int get _amountUzs => int.tryParse(_amount.text.replaceAll(' ', '')) ?? 0;

  String get _locale => Localizations.localeOf(context).languageCode;

  /// Creates the pending top-up, opens [provider]'s checkout, then polls the
  /// balance until the callback lands.
  Future<void> _pay(String provider) async {
    final l = context.l10n;
    if (_amountUzs < _minTopUp) {
      showErrorSnack(context, l.walletErrAmount);
      return;
    }
    setState(() => _busy = true);
    final locale = _locale;
    try {
      final wallet = ref.read(walletProvider).value;
      _balanceBefore = wallet?.balanceUzs ?? 0;

      final repo = ref.read(walletRepositoryProvider);
      final order = await repo.createTopUpOrder(_amountUzs);
      // The gateway needs somewhere to send the payer back to; the web wallet
      // page is that landing spot, while the app confirms by polling.
      final returnUrl = '${Env.webBaseUrl}/$locale/employer/wallet';
      final String url;
      if (provider == 'rahmat') {
        // Multicard mints a per-invoice URL; the shared `rahmat-invoice` helper
        // works for any order kind, top-ups included.
        url = await ref
            .read(employerJobsRepositoryProvider)
            .createRahmatCheckout(orderId: order.orderId, returnUrl: returnUrl);
      } else if (provider == 'click') {
        url = clickCheckoutUrl(
          serviceId: Env.clickServiceId,
          merchantId: Env.clickMerchantId,
          orderId: order.orderId,
          amountUzs: order.amountUzs,
          returnUrl: returnUrl,
        );
      } else {
        url = paymeCheckoutUrl(
          merchantId: Env.paymeMerchantId,
          orderId: order.orderId,
          amountUzs: order.amountUzs,
          returnUrl: returnUrl,
        );
      }

      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      if (!launched) {
        showErrorSnack(context, l.payError);
        return;
      }
      setState(() => _awaiting = true);
      _startPolling();
    } catch (e) {
      if (mounted) showErrorSnack(context, l.payError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _checkBalance());
  }

  Future<void> _checkBalance() async {
    final before = _balanceBefore ?? 0;
    ref.invalidate(walletProvider);
    final wallet = await ref.read(walletProvider.future);
    if (!mounted) return;
    if (wallet.balanceUzs > before) {
      _poll?.cancel();
      setState(() => _awaiting = false);
      showInfoSnack(context, context.l10n.walletToppedUp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final async = ref.watch(walletProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.walletTitle),
            ),
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
                  onRefresh: () async {
                    ref.invalidate(walletProvider);
                    await ref.read(walletProvider.future);
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    children: [
                      _BalanceCard(balanceUzs: wallet.balanceUzs),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTopUp(context),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        l.walletHistory,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (wallet.transactions.isEmpty)
                        Text(
                          l.walletHistoryEmpty,
                          style: context.text.bodySmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        )
                      else
                        for (final tx in wallet.transactions)
                          _LedgerRow(tx: tx),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopUp(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final configured = Env.hasPaymentGateway;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.walletTopUp,
          style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          l.walletTopUpSub,
          style: context.text.bodySmall?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final preset in _presets)
              ChoiceChip(
                label: Text(formatUzs(preset)),
                selected: _amountUzs == preset,
                onSelected: (_) =>
                    setState(() => _amount.text = preset.toString()),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _amount,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l.walletAmountHint),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_awaiting)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.chipBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l.payConfirmingTitle,
                    style: context.text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (!configured)
          // Honest about the state of the world: the request is still recorded
          // (the finance team can confirm it by hand), but nothing is charged.
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.chipBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              l.payUnconfigured,
              style: context.text.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          )
        else ...[
          if (Env.hasRahmat)
            JzPrimaryButton(
              label: l.payWithRahmat,
              icon: Icons.qr_code_2_rounded,
              loading: _busy,
              onPressed: _busy ? null : () => _pay('rahmat'),
            ),
          if (Env.hasRahmat && (Env.hasPayme || Env.hasClick))
            const SizedBox(height: AppSpacing.sm),
          if (Env.hasPayme)
            Env.hasRahmat
                ? OutlinedButton.icon(
                    onPressed: _busy ? null : () => _pay('payme'),
                    icon: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 20,
                    ),
                    label: Text(l.payWithPayme),
                  )
                : JzPrimaryButton(
                    label: l.payWithPayme,
                    loading: _busy,
                    onPressed: _busy ? null : () => _pay('payme'),
                  ),
          if (Env.hasPayme && Env.hasClick)
            const SizedBox(height: AppSpacing.sm),
          if (Env.hasClick)
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _pay('click'),
              icon: const Icon(Icons.credit_card_rounded, size: 20),
              label: Text(l.payWithClick),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l.walletPayNote,
            style: context.text.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balanceUzs});
  final num balanceUzs;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.walletBalanceLabel,
            style: context.text.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            formatUzs(balanceUzs),
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l.walletBalanceHint,
            style: context.text.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.tx});
  final WalletTransaction tx;

  String _kindLabel(BuildContext context) => switch (tx.kind) {
    'topup' => context.l10n.walletKindTopup,
    'spend' => context.l10n.walletKindSpend,
    'refund' => context.l10n.walletKindRefund,
    _ => context.l10n.walletKindBonus,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final credit = tx.isCredit;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description?.isNotEmpty == true
                      ? tx.description!
                      : _kindLabel(context),
                  style: context.text.bodyMedium,
                ),
                Text(
                  tx.isPending
                      ? context.l10n.walletStatusPending
                      : _kindLabel(context),
                  style: context.text.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${credit ? '+' : '−'}${formatUzs(tx.amountUzs.abs())}',
            style: context.text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: tx.isPending
                  ? colors.textSecondary
                  : (credit ? colors.success : colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
