import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../application/auth_controller.dart';
import '../../domain/auth_repository.dart';
import '../util/auth_failure_message.dart';
import 'verify_code_page.dart';

class CreateAccountPage extends ConsumerStatefulWidget {
  const CreateAccountPage({super.key});

  @override
  ConsumerState<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends ConsumerState<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _email.text.trim();
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signUp(
          email: email,
          password: _password.text,
          fullName: _name.text.trim().isEmpty ? null : _name.text.trim(),
        );
    if (!mounted) return;
    if (ok) {
      context.push(
        Routes.verifyCode,
        extra: VerifyCodeArgs(email: email, purpose: OtpPurpose.signup),
      );
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
      title: l.createAccount,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            JzTextField(
              label: l.fullName,
              controller: _name,
              prefixIcon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: AppSpacing.lg),
            JzTextField(
              label: l.email,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.mail_outline_rounded,
              validator: (v) => Validators.isEmail(v ?? '') ? null : l.valEmail,
            ),
            const SizedBox(height: AppSpacing.lg),
            JzTextField(
              label: l.password,
              controller: _password,
              obscureText: true,
              prefixIcon: Icons.lock_outline_rounded,
              validator: (v) => Validators.isStrongEnough(v ?? '')
                  ? null
                  : l.valPasswordShort,
            ),
            const SizedBox(height: AppSpacing.xl),
            JzPrimaryButton(
              label: l.createAccount,
              loading: loading,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l.alreadyHaveAccount),
                TextButton(
                  onPressed: () => context.go(Routes.signIn),
                  child: Text(l.signIn),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
