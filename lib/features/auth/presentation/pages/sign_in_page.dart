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

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signIn(email: _email.text.trim(), password: _password.text);
    if (!mounted) return;
    if (ok) {
      context.go(Routes.home);
    } else {
      showErrorSnack(
        context,
        authFailureMessage(context, ref.read(authControllerProvider).error!),
      );
    }
  }

  Future<void> _forgotPassword() async {
    final l = context.l10n;
    final emailCtrl = TextEditingController(text: _email.text.trim());
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: Consumer(
          builder: (ctx, sheetRef, _) {
            final loading = sheetRef.watch(authControllerProvider).isLoading;
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.forgotPasswordTitle, style: ctx.text.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l.forgotPasswordSubtitle,
                    style: ctx.text.bodyMedium?.copyWith(
                      color: ctx.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  JzTextField(
                    label: l.email,
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  JzPrimaryButton(
                    label: l.sendCode,
                    loading: loading,
                    onPressed: () async {
                      final email = emailCtrl.text.trim();
                      if (!Validators.isEmail(email)) {
                        showErrorSnack(ctx, l.valEmail);
                        return;
                      }
                      final notifier = sheetRef.read(
                        authControllerProvider.notifier,
                      );
                      final ok = await notifier.sendPasswordReset(email);
                      if (!ctx.mounted) return;
                      if (!ok) {
                        showErrorSnack(
                          ctx,
                          authFailureMessage(
                            ctx,
                            sheetRef.read(authControllerProvider).error!,
                          ),
                        );
                        return;
                      }
                      Navigator.of(ctx).pop();
                      if (mounted) {
                        context.push(
                          Routes.verifyCode,
                          extra: VerifyCodeArgs(
                            email: email,
                            purpose: OtpPurpose.recovery,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            );
          },
        ),
      ),
    );
    emailCtrl.dispose();
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
              AuthHeader(title: l.signIn, subtitle: l.signInSubtitle),
              const SizedBox(height: AppSpacing.xxl),
              JzTextField(
                label: l.email,
                hint: 'example@gmail.com',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    Validators.isEmail(v ?? '') ? null : l.valEmail,
              ),
              const SizedBox(height: AppSpacing.lg),
              JzPasswordField(
                label: l.password,
                controller: _password,
                validator: (v) =>
                    Validators.isNotBlank(v) ? null : l.valRequired,
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _forgotPassword,
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
              const SizedBox(height: AppSpacing.xl),
              JzPrimaryButton(
                label: l.signIn,
                loading: loading,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.xl),
              AuthSocialRow(label: l.orSignInWith),
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
                    l.dontHaveAccount,
                    style: context.text.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  GestureDetector(
                    onTap: () => context.push(Routes.createAccount),
                    child: Text(
                      l.signUp,
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
