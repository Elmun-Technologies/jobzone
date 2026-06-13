import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/enums/enums.dart';
import '../application/preferences_controller.dart';
import 'widgets/preference_step.dart';

class ExperienceLevelPage extends ConsumerWidget {
  const ExperienceLevelPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final draft = ref.watch(preferencesControllerProvider);
    final notifier = ref.read(preferencesControllerProvider.notifier);
    final options = {
      ExperienceLevel.entry.wire: l.expEntry,
      ExperienceLevel.mid.wire: l.expMid,
      ExperienceLevel.senior.wire: l.expSenior,
      ExperienceLevel.lead.wire: l.expLead,
    };
    return PreferenceStepScaffold(
      title: l.prefExperienceTitle,
      subtitle: l.prefSelectMultiple,
      nextLabel: l.next,
      onNext: () => context.push(Routes.setupWorkingModel),
      child: MultiSelectChips(
        options: options,
        selected: draft.experienceLevels,
        onToggle: notifier.toggleExperience,
      ),
    );
  }
}
