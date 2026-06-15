import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/enums/enums.dart';
import '../../../shared/widgets/snackbars.dart';
import '../../profile/data/cv_repository.dart';
import '../../profile/data/profile_repository.dart';

class SeekingStatusPage extends ConsumerStatefulWidget {
  const SeekingStatusPage({super.key});

  @override
  ConsumerState<SeekingStatusPage> createState() => _SeekingStatusPageState();
}

class _SeekingStatusPageState extends ConsumerState<SeekingStatusPage> {
  SeekingStatus? _status;
  bool? _openToWork;
  bool _saving = false;

  String _label(BuildContext c, SeekingStatus s) => switch (s) {
    SeekingStatus.activelyLooking => c.l10n.seekingActive,
    SeekingStatus.openToOffers => c.l10n.seekingOpen,
    SeekingStatus.notLooking => c.l10n.seekingNot,
  };

  String _desc(BuildContext c, SeekingStatus s) => switch (s) {
    SeekingStatus.activelyLooking => c.l10n.seekingActiveDesc,
    SeekingStatus.openToOffers => c.l10n.seekingOpenDesc,
    SeekingStatus.notLooking => c.l10n.seekingNotDesc,
  };

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(cvRepositoryProvider)
          .setSeekingStatus(_status!, openToWork: _openToWork ?? true);
      ref.invalidate(currentProfileProvider);
      if (mounted) {
        showInfoSnack(context, context.l10n.saved);
        context.pop();
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
    final async = ref.watch(currentProfileProvider);

    return JzScaffold(
      title: l.jobSeekingStatus,
      body: async.when(
        loading: () => const JzLoader(),
        error: (_, _) => Center(child: Text(l.errUnknown)),
        data: (profile) {
          _status ??= profile?.seekingStatus ?? SeekingStatus.activelyLooking;
          _openToWork ??= profile?.isOpenToWork ?? true;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    for (final s in SeekingStatus.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _StatusCard(
                          label: _label(context, s),
                          description: _desc(context, s),
                          selected: _status == s,
                          onTap: () => setState(() => _status = s),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.openToWork),
                      subtitle: Text(l.openToWorkHint),
                      value: _openToWork!,
                      onChanged: (v) => setState(() => _openToWork = v),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: JzPrimaryButton(
                    label: l.save,
                    loading: _saving,
                    onPressed: _save,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected
              ? colors.primary.withValues(alpha: 0.06)
              : colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? colors.primary : colors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.text.titleSmall),
                  Text(
                    description,
                    style: context.text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
