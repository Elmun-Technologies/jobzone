import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/enums/enums.dart';
import '../application/preferences_controller.dart';
import 'widgets/preference_step.dart';

class JobTypePage extends ConsumerWidget {
  const JobTypePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final draft = ref.watch(preferencesControllerProvider);
    final notifier = ref.read(preferencesControllerProvider.notifier);
    final options = {
      JobType.fullTime.wire: l.jobTypeFullTime,
      JobType.partTime.wire: l.jobTypePartTime,
      JobType.contract.wire: l.jobTypeContract,
      JobType.internship.wire: l.jobTypeInternship,
      JobType.temporary.wire: l.jobTypeTemporary,
    };
    return PreferenceStepScaffold(
      title: l.prefJobTypeTitle,
      subtitle: l.prefSelectMultiple,
      nextLabel: l.next,
      onNext: () => context.push(Routes.setupExperience),
      child: MultiSelectChips(
        options: options,
        selected: draft.jobTypes,
        onToggle: notifier.toggleJobType,
      ),
    );
  }
}
