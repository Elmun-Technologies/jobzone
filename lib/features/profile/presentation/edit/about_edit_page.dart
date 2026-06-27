import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../data/cv_repository.dart';
import '../../data/profile_repository.dart';
import 'widgets/edit_form_scaffold.dart';

/// Edits the headline / bio plus the "open to work" flag on the profile row.
class AboutEditPage extends ConsumerStatefulWidget {
  const AboutEditPage({super.key});

  @override
  ConsumerState<AboutEditPage> createState() => _AboutEditPageState();
}

class _AboutEditPageState extends ConsumerState<AboutEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _headline = TextEditingController();
  final _bio = TextEditingController();
  bool _openToWork = true;
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _fullName.dispose();
    _headline.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(cvRepositoryProvider);
      await repo.saveAbout(
        fullName: _fullName.text.trim(),
        headline: _nullable(_headline.text),
        bio: _nullable(_bio.text),
      );
      await repo.setOpenToWork(_openToWork);
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
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      loading: () => JzScaffold(title: l.sectionAbout, body: const JzLoader()),
      error: (_, _) => JzScaffold(
        title: l.sectionAbout,
        body: JzErrorState(
          title: l.errorTitle,
          message: l.errUnknown,
          retryLabel: l.retry,
          onRetry: () => ref.invalidate(currentProfileProvider),
        ),
      ),
      data: (profile) {
        if (!_initialized) {
          _fullName.text = profile?.fullName ?? '';
          _headline.text = profile?.headline ?? '';
          _bio.text = profile?.bio ?? '';
          _openToWork = profile?.isOpenToWork ?? true;
          _initialized = true;
        }
        return EditFormScaffold(
          title: l.sectionAbout,
          formKey: _formKey,
          saving: _saving,
          onSave: _save,
          children: [
            JzTextField(
              label: l.fullName,
              controller: _fullName,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.valRequired : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            JzTextField(
              label: l.headline,
              controller: _headline,
              hint: l.headlineHint,
            ),
            const SizedBox(height: AppSpacing.lg),
            JzTextField(
              label: l.bioLabel,
              controller: _bio,
              hint: l.bioHint,
              maxLines: 6,
              minLines: 4,
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.openToWork),
              subtitle: Text(l.openToWorkHint),
              value: _openToWork,
              onChanged: (v) => setState(() => _openToWork = v),
            ),
          ],
        );
      },
    );
  }
}

String? _nullable(String s) => s.trim().isEmpty ? null : s.trim();
