import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../application/auth_controller.dart';
import '../util/auth_failure_message.dart';

class NewPasswordPage extends ConsumerStatefulWidget {
  const NewPasswordPage({super.key});

  @override
  ConsumerState<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends ConsumerState<NewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .updatePassword(_password.text);
    if (!mounted) return;
    if (ok) {
      showInfoSnack(context, context.l10n.passwordUpdated);
      context.go(Routes.home);
    } else {
      showErrorSnack(
        context,
        authFailureMessage(context, ref.read(authControllerProvider).error!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final loading = ref.watch(authControllerProvider).isLoading;
    return JzScaffold(
      title: l.newPasswordTitle,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text(
              l.newPasswordSubtitle,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            JzTextField(
              label: l.password,
              controller: _password,
              obscureText: true,
              prefixIcon: Icons.lock_outline_rounded,
              validator: (v) => Validators.isStrongEnough(v ?? '')
                  ? null
                  : l.valPasswordShort,
            ),
            const SizedBox(height: AppSpacing.lg),
            JzTextField(
              label: l.confirmPassword,
              controller: _confirm,
              obscureText: true,
              prefixIcon: Icons.lock_outline_rounded,
              validator: (v) =>
                  v == _password.text ? null : l.valPasswordMismatch,
            ),
            const SizedBox(height: AppSpacing.xl),
            JzPrimaryButton(
              label: l.save,
              loading: loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
