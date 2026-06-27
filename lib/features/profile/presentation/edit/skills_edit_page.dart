import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../application/cv_providers.dart';
import '../../data/profile_repository.dart';
import 'widgets/edit_form_scaffold.dart';

class SkillsEditPage extends ConsumerStatefulWidget {
  const SkillsEditPage({super.key});

  @override
  ConsumerState<SkillsEditPage> createState() => _SkillsEditPageState();
}

class _SkillsEditPageState extends ConsumerState<SkillsEditPage> {
  final _input = TextEditingController();
  final _skills = <String>[];
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add() {
    final value = _input.text.trim();
    if (value.isEmpty) return;
    if (!_skills.any((s) => s.toLowerCase() == value.toLowerCase())) {
      setState(() => _skills.add(value));
    }
    _input.clear();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(skillsControllerProvider.notifier).save(_skills);
      ref.invalidate(currentProfileProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, localizedError(context, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final async = ref.watch(skillsControllerProvider);

    return async.when(
      loading: () => JzScaffold(title: l.sectionSkills, body: const JzLoader()),
      error: (_, _) => JzScaffold(
        title: l.sectionSkills,
        body: JzErrorState(
          title: l.errorTitle,
          message: l.errUnknown,
          retryLabel: l.retry,
          onRetry: () => ref.invalidate(skillsControllerProvider),
        ),
      ),
      data: (skills) {
        if (!_initialized) {
          _skills.addAll(skills);
          _initialized = true;
        }
        return EditFormScaffold(
          title: l.sectionSkills,
          saving: _saving,
          onSave: _save,
          children: [
            JzTextField(
              label: l.addSkillLabel,
              controller: _input,
              hint: l.addSkillHint,
              textInputAction: TextInputAction.done,
              onChanged: (_) {},
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: _add,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_skills.isEmpty)
              Text(
                l.noEntriesYet,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final s in _skills)
                    Chip(
                      label: Text(s),
                      onDeleted: () => setState(() => _skills.remove(s)),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}
