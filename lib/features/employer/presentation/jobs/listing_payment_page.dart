import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/env.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../../monetization/domain/checkout_url.dart';
import '../../../monetization/domain/listing_tier.dart';
import '../../../monetization/domain/promotion.dart' show formatUzs;
import '../../data/employer_jobs_repository.dart';

/// Direct pay-per-listing checkout for a draft vacancy (the employer's 2nd+
/// post). Pick a tier → open Payme/Click → the gateway callback publishes the
/// draft with that tier. The page polls the job status and turns into the
/// "published" state on its own once the callback lands. Reached from
/// `PostJobPage._submit` after the draft is created; the web twin is
/// `/employer/jobs/[id]/pay` + `/paid`.
class ListingPaymentPage extends ConsumerStatefulWidget {
  const ListingPaymentPage({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  final String jobId;
  final String jobTitle;

  @override
  ConsumerState<ListingPaymentPage> createState() => _ListingPaymentPageState();
}

enum _Phase { selecting, confirming, published }

class _ListingPaymentPageState extends ConsumerState<ListingPaymentPage> {
  // Brend is the default — the nudge tier (its logo lights up).
  ListingTier _tier = ListingTier.brand;
  _Phase _phase = _Phase.selecting;
  bool _busy = false;
  Timer? _poll;

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  String get _locale => Localizations.localeOf(context).languageCode;

  /// Opens the gateway for [provider] ("payme" | "click"): creates the order,
  /// builds the checkout URL, launches it externally, then starts polling.
  Future<void> _pay(String provider) async {
    setState(() => _busy = true);
    final repo = ref.read(employerJobsRepositoryProvider);
    // Read the locale before any await so we don't touch context afterwards.
    final locale = _locale;
    try {
      final order = await repo.createListingOrder(
        jobId: widget.jobId,
        tierCode: 'tier_${_tier.name}',
      );
      final returnUrl =
          '${Env.webBaseUrl}/$locale/employer/jobs/${widget.jobId}/paid';
      final url = provider == 'click'
          ? clickCheckoutUrl(
              serviceId: Env.clickServiceId,
              merchantId: Env.clickMerchantId,
              orderId: order.orderId,
              amountUzs: order.amountUzs,
              returnUrl: returnUrl,
            )
          : paymeCheckoutUrl(
              merchantId: Env.paymeMerchantId,
              orderId: order.orderId,
              amountUzs: order.amountUzs,
              returnUrl: returnUrl,
            );
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      if (!launched) {
        showErrorSnack(context, context.l10n.payError);
        return;
      }
      setState(() => _phase = _Phase.confirming);
      _startPolling();
    } catch (e) {
      if (mounted) showErrorSnack(context, context.l10n.payError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    final status = await ref
        .read(employerJobsRepositoryProvider)
        .jobStatus(widget.jobId);
    if (!mounted) return;
    if (status == 'open') {
      _poll?.cancel();
      ref.invalidate(myJobsProvider);
      setState(() => _phase = _Phase.published);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.payListingTitle),
            ),
            Expanded(
              child: switch (_phase) {
                _Phase.selecting => _buildSelecting(context),
                _Phase.confirming => _buildConfirming(context),
                _Phase.published => _buildPublished(context),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelecting(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final configured = Env.hasPaymentGateway;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        Text(
          l.payListingSubtitle(widget.jobTitle),
          style: context.text.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final info in kListingTiers)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _SelectableTierCard(
              info: info,
              selected: info.tier == _tier,
              onTap: () => setState(() => _tier = info.tier),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        if (!configured)
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
          if (Env.hasPayme)
            JzPrimaryButton(
              label: l.payWithPayme,
              icon: Icons.account_balance_wallet_rounded,
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
          const SizedBox(height: AppSpacing.md),
          Text(
            l.payNote,
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConfirming(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l.payConfirmingTitle,
            textAlign: TextAlign.center,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l.payConfirmingSubtitle,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton(onPressed: _checkStatus, child: Text(l.payCheckStatus)),
        ],
      ),
    );
  }

  Widget _buildPublished(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, size: 72, color: colors.primary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l.payPublishedTitle,
            textAlign: TextAlign.center,
            style: context.text.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l.payPublishedSubtitle,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          JzPrimaryButton(
            label: l.payViewMyJobs,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
}

/// A compact, tappable tier card for the post-time picker (name · tagline ·
/// price with a radio dot). The full marketing card lives in `tiers_page.dart`.
class _SelectableTierCard extends StatelessWidget {
  const _SelectableTierCard({
    required this.info,
    required this.selected,
    required this.onTap,
  });

  final ListingTierInfo info;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final name = switch (info.tier) {
      ListingTier.standard => l.tierStandardName,
      ListingTier.brand => l.tierBrandName,
      ListingTier.premium => l.tierPremiumName,
    };
    final tagline = switch (info.tier) {
      ListingTier.standard => l.tierStandardTagline,
      ListingTier.brand => l.tierBrandTagline,
      ListingTier.premium => l.tierPremiumTagline,
    };
    // The nudge badges from the pricing page, kept on the picker too.
    final badge = switch (info.tier) {
      ListingTier.standard => null,
      ListingTier.brand => l.tierPopular,
      ListingTier.premium => l.tierBestResult,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? colors.chipBackground : colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? colors.primary : colors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: AppSpacing.sm),
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
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tagline,
                    style: context.text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              formatUzs(info.priceUzs),
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
