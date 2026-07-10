import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/options/option_lists.dart';
import '../application/preferences_controller.dart';
import 'widgets/preference_step.dart';

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
      // Localized blue-collar keywords (wire = the Uzbek keyword matched
      // against real job titles) — see shared/options/option_lists.dart.
      child: OptionCheckList(
        options: jobTitleOptions(l),
        selected: selected,
        onToggle: notifier.toggleTitle,
      ),
    );
  }
}
