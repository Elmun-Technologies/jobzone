import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';

/// Static sign-in form. Real Supabase auth is wired in the Auth phase; for now
/// "Sign In" enters the app shell so the foundation is demoable end-to-end.
class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return JzScaffold(
      title: l.signIn,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text(
            l.signInSubtitle,
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          JzTextField(
            label: l.email,
            hint: 'name@example.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          JzTextField(
            label: l.password,
            obscureText: true,
            prefixIcon: Icons.lock_outline_rounded,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push(Routes.newPassword),
              child: Text(l.forgotPassword),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          JzPrimaryButton(
            label: l.signIn,
            onPressed: () => context.go(Routes.home),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l.dontHaveAccount),
              TextButton(
                onPressed: () => context.push(Routes.createAccount),
                child: Text(l.createAccount),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
