import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> _select(SeekingStatus s) async {
    setState(() => _status = s);
    try {
      await ref
          .read(cvRepositoryProvider)
          .setSeekingStatus(s, openToWork: s != SeekingStatus.notLooking);
      ref.invalidate(currentProfileProvider);
    } catch (e) {
      if (mounted) showErrorSnack(context, localizedError(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final async = ref.watch(currentProfileProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.jobSeekingStatus),
            ),
            Expanded(
              child: async.when(
                loading: () => const JzLoader(),
                error: (_, _) => Center(child: Text(l.errUnknown)),
                data: (profile) {
                  _status ??=
                      profile?.seekingStatus ?? SeekingStatus.activelyLooking;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    children: [
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(
                            Icons.visibility_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l.seekingStatusSubtitle,
                        textAlign: TextAlign.center,
                        style: context.text.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      for (final s in SeekingStatus.values)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _StatusRow(
                            label: _label(context, s),
                            description: _desc(context, s),
                            selected: _status == s,
                            onTap: () => _select(s),
                          ),
                        ),
                    ],
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

class _StatusRow extends StatelessWidget {
  const _StatusRow({
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
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: JzRadio(selected: selected),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    description,
                    style: context.text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      height: 1.4,
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
