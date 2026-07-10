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
import '../widgets/auth_header.dart';
import '../widgets/auth_social_row.dart';
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
  bool _agree = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      // The checkbox was inert before — unchecking it still let signup proceed.
      final l = context.l10n;
      showInfoSnack(context, l.mustAgreeToTerms);
      return;
    }
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
    final colors = context.colors;
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
                title: l.createAccount,
                subtitle: l.createAccountSubtitle,
              ),
              const SizedBox(height: AppSpacing.xxl),
              JzTextField(
                label: l.fullName,
                hint: l.nameHint,
                controller: _name,
              ),
              const SizedBox(height: AppSpacing.lg),
              JzTextField(
                label: l.email,
                hint: context.l10n.emailHint,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    Validators.isEmail(v ?? '') ? null : l.valEmail,
              ),
              const SizedBox(height: AppSpacing.lg),
              JzPasswordField(
                label: l.password,
                controller: _password,
                validator: (v) => Validators.isStrongEnough(v ?? '')
                    ? null
                    : l.valPasswordShort,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agree,
                      activeColor: colors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      onChanged: (v) => setState(() => _agree = v ?? false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${l.agreeWithTerms} ',
                          style: context.text.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(content: Text(l.comingSoon)),
                            ),
                          child: Text(
                            l.termsAndConditions,
                            style: context.text.bodyMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              JzPrimaryButton(
                label: l.signUp,
                loading: loading,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.xl),
              AuthSocialRow(label: l.orSignUpWith),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () => context.push(Routes.phoneSignIn),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(l.continueWithPhone),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l.alreadyHaveAccount,
                    style: context.text.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  GestureDetector(
                    onTap: () => context.go(Routes.signIn),
                    child: Text(
                      l.signIn,
                      style: context.text.bodyMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
