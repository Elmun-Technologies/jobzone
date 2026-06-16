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
import '../widgets/auth_header.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            children: [
              AuthHeader(
                title: l.newPasswordTitle,
                subtitle: l.newPasswordSubtitle,
                showBack: true,
              ),
              const SizedBox(height: AppSpacing.xxl),
              JzPasswordField(
                label: l.password,
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
              const SizedBox(height: AppSpacing.xxl),
              JzPrimaryButton(
                label: l.createNewPassword,
                loading: loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
