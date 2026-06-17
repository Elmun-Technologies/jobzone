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
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
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
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.passwordManager),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  children: [
                    JzPasswordField(
                      label: l.currentPassword,
                      controller: _current,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(content: Text(l.comingSoon))),
                        child: Text(
                          l.forgotPassword,
                          style: context.text.bodyMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    JzPasswordField(
                      label: l.newPasswordTitle,
                      controller: _password,
                      validator: (v) => Validators.isStrongEnough(v ?? '')
                          ? null
                          : l.valPasswordShort,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    JzPasswordField(
                      label: l.confirmPassword,
                      controller: _confirm,
                      validator: (v) =>
                          v == _password.text ? null : l.valPasswordMismatch,
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: JzPrimaryButton(
                  label: l.passwordManager,
                  loading: _saving,
                  onPressed: _save,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
