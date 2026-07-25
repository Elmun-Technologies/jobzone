import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/enums/enums.dart';
import '../application/preferences_controller.dart';
import 'widgets/preference_step.dart';

class WorkingModelPage extends ConsumerWidget {
  const WorkingModelPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final draft = ref.watch(preferencesControllerProvider);
    final notifier = ref.read(preferencesControllerProvider.notifier);
    final options = {
      WorkingModel.onsite.wire: l.wmOnsite,
      WorkingModel.hybrid.wire: l.wmHybrid,
      WorkingModel.remote.wire: l.wmRemote,
    };
    return PreferenceStepScaffold(
      title: l.prefWorkingModelTitle,
      step: 3,
      totalSteps: 4,
      nextLabel: l.next,
      onNext: () => context.push(Routes.setupJobTitle),
      // Skip persists whatever has been picked so far and jumps past the rest
      // of the chain — none of these answers is needed to browse jobs.
      skipLabel: l.skip,
      onSkip: () async {
        final router = GoRouter.of(context);
        await notifier.persist();
        router.push(Routes.permLocation);
      },
      child: OptionCheckList(
        options: options,
        selected: draft.workingModels,
        onToggle: notifier.toggleWorkingModel,
      ),
    );
  }
}
