import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../localization/l10n_extension.dart';
import '../application/preferences_controller.dart';
import 'widgets/preference_step.dart';

/// Predefined job titles shown as a multi-select checklist (matches the
/// Figma "What Job Title Are You Seeking?" screen).
const _jobTitles = <String>[
  'Accountant',
  'Business Development Manager',
  'Content Writer',
  'Data Analyst',
  'Finance Manager',
  'Graphic Designer',
  'HR Specialist',
  'Human Resources Manager',
  'Marketing Manager',
  'Product Manager',
  'Project Manager',
  'Sales Manager',
  'Software Engineer',
  'UX/UI Designer',
];

class JobTitlePage extends ConsumerWidget {
  const JobTitlePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final selected = ref.watch(preferencesControllerProvider).titles.toSet();
    final notifier = ref.read(preferencesControllerProvider.notifier);

    return PreferenceStepScaffold(
      title: l.prefJobTitleTitle,
      step: 4,
      totalSteps: 4,
      nextLabel: l.next,
      onNext: () async {
        final router = GoRouter.of(context);
        await notifier.persist();
        router.push(Routes.permLocation);
      },
      child: OptionCheckList(
        options: {for (final t in _jobTitles) t: t},
        selected: selected,
        onToggle: notifier.toggleTitle,
      ),
    );
  }
}
