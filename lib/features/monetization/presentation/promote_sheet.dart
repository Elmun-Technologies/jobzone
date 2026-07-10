import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../data/monetization_repository.dart';
import 'widgets/promo_package_card.dart';

/// Opens the gamified "promote this job" package picker.
Future<void> showPromoteSheet(BuildContext context, {required String jobId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => _PromoteSheet(jobId: jobId),
  );
}

class _PromoteSheet extends ConsumerStatefulWidget {
  const _PromoteSheet({required this.jobId});
  final String jobId;

  @override
  ConsumerState<_PromoteSheet> createState() => _PromoteSheetState();
}

class _PromoteSheetState extends ConsumerState<_PromoteSheet> {
  String? _selected;

  void _continue() {
    final code = _selected;
    if (code == null) return;
    // Close the sheet, then open checkout (capture the router first — the
    // sheet's context is deactivated after pop).
    final router = GoRouter.of(context);
    Navigator.pop(context);
    router.push(Routes.checkout(widget.jobId, code));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final async = ref.watch(promotionProductsProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l.choosePackage,
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // The package list scrolls — five cards overflow small phones, and
            // previously pushed the Continue button off-screen (it now stays
            // pinned below the scroll area).
            Flexible(
              child: SingleChildScrollView(
                child: async.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: JzLoader(),
                  ),
                  error: (_, _) => JzErrorState(
                    title: l.errorTitle,
                    message: l.errUnknown,
                    retryLabel: l.retry,
                    onRetry: () => ref.invalidate(promotionProductsProvider),
                  ),
                  data: (products) {
                    // Skip the free "start" base (promoting is a paid boost)
                    // and any not-yet-live "coming soon" tiers (kind 'ai').
                    final buyable = [
                      for (final p in products)
                        if (p.kind != 'base' && !p.isComingSoon) p,
                    ];
                    return Column(
                      children: [
                        for (final p in buyable)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: PromoPackageCard(
                              product: p,
                              selected: _selected == p.code,
                              onTap: () => setState(() => _selected = p.code),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            JzPrimaryButton(
              label: l.continueLabel,
              onPressed: _selected == null ? null : _continue,
            ),
          ],
        ),
      ),
    );
  }
}
