import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/widgets/snackbars.dart';
import '../../employer/data/employer_jobs_repository.dart';
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
  bool _saving = false;

  Future<void> _buy() async {
    final code = _selected;
    if (code == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(monetizationRepositoryProvider)
          .purchase(jobId: widget.jobId, productCode: code);
      ref.invalidate(myJobsProvider);
      ref.invalidate(myOrdersProvider);
      if (mounted) {
        showInfoSnack(context, context.l10n.promotedToast);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: JzLoader(),
            ),
            error: (_, _) => Text(l.errUnknown),
            data: (products) {
              // Skip the free "start" base — promoting means a paid boost.
              final buyable = [
                for (final p in products)
                  if (p.kind != 'base') p,
              ];
              return Column(
                children: [
                  for (final p in buyable)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
          const SizedBox(height: AppSpacing.sm),
          JzPrimaryButton(
            label: l.buyCta,
            loading: _saving,
            onPressed: _selected == null ? null : _buy,
          ),
        ],
      ),
    );
  }
}
