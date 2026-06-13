import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../application/preferences_controller.dart';
import 'widgets/preference_step.dart';

class JobTitlePage extends ConsumerStatefulWidget {
  const JobTitlePage({super.key});

  @override
  ConsumerState<JobTitlePage> createState() => _JobTitlePageState();
}

class _JobTitlePageState extends ConsumerState<JobTitlePage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    ref.read(preferencesControllerProvider.notifier).addTitle(_controller.text);
    _controller.clear();
  }

  Future<void> _finish() async {
    await ref.read(preferencesControllerProvider.notifier).persist();
    if (mounted) context.push(Routes.permLocation);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final titles = ref.watch(preferencesControllerProvider).titles;
    return PreferenceStepScaffold(
      title: l.prefJobTitleTitle,
      nextLabel: l.next,
      onNext: _finish,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: JzTextField(
                  hint: l.prefJobTitleHint,
                  controller: _controller,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {},
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(
                onPressed: _add,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final title in titles)
                Chip(
                  label: Text(title),
                  onDeleted: () => ref
                      .read(preferencesControllerProvider.notifier)
                      .removeTitle(title),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
