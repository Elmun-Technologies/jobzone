import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/utils/validators.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/widgets/snackbars.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/presentation/util/auth_failure_message.dart';
import '../../profile/presentation/edit/widgets/edit_form_scaffold.dart';

/// Change the account password (Supabase `updateUser`). Offline it just
/// confirms, since there's no auth backend.
class PasswordManagerPage extends ConsumerStatefulWidget {
  const PasswordManagerPage({super.key});

  @override
  ConsumerState<PasswordManagerPage> createState() =>
      _PasswordManagerPageState();
}

class _PasswordManagerPageState extends ConsumerState<PasswordManagerPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (Env.hasSupabase) {
        final ok = await ref
            .read(authControllerProvider.notifier)
            .updatePassword(_password.text);
        if (!ok) {
          if (mounted) {
            final err = ref.read(authControllerProvider).error;
            showErrorSnack(context, authFailureMessage(context, err!));
          }
          return;
        }
      }
      if (mounted) {
        showInfoSnack(context, context.l10n.passwordUpdated);
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return EditFormScaffold(
      title: l.passwordManager,
      formKey: _formKey,
      saving: _saving,
      onSave: _save,
      children: [
        JzTextField(
          label: l.newPasswordTitle,
          controller: _password,
          obscureText: true,
          textInputAction: TextInputAction.next,
          validator: (v) =>
              Validators.isStrongEnough(v ?? '') ? null : l.valPasswordShort,
        ),
        const SizedBox(height: AppSpacing.lg),
        JzTextField(
          label: l.confirmPassword,
          controller: _confirm,
          obscureText: true,
          validator: (v) => v == _password.text ? null : l.valPasswordMismatch,
        ),
      ],
    );
  }
}
