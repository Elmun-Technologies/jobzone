import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../../app/router/routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../application/auth_controller.dart';
import '../../domain/auth_repository.dart';
import '../util/auth_failure_message.dart';

class VerifyCodeArgs {
  const VerifyCodeArgs({required this.email, required this.purpose});
  final String email;
  final OtpPurpose purpose;
}

class VerifyCodePage extends ConsumerStatefulWidget {
  const VerifyCodePage({super.key, required this.args});
  final VerifyCodeArgs args;

  @override
  ConsumerState<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends ConsumerState<VerifyCodePage> {
  final _pin = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _verify(String code) async {
    final notifier = ref.read(authControllerProvider.notifier);
    final isSignup = widget.args.purpose == OtpPurpose.signup;
    final ok = isSignup
        ? await notifier.verifySignup(email: widget.args.email, token: code)
        : await notifier.verifyRecovery(email: widget.args.email, token: code);
    if (!mounted) return;
    if (ok) {
      isSignup
          ? context.go(Routes.completeProfile)
          : context.push(Routes.newPassword);
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

    final base = PinTheme(
      width: 52,
      height: 56,
      textStyle: context.text.titleLarge,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );

    return JzScaffold(
      title: l.verifyCodeTitle,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text(
            l.verifyCodeSubtitle(widget.args.email),
            style: context.text.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Pinput(
            length: 6,
            controller: _pin,
            defaultPinTheme: base,
            focusedPinTheme: base.copyWith(
              decoration: base.decoration!.copyWith(
                border: Border.all(color: colors.primary, width: 1.5),
              ),
            ),
            onCompleted: _verify,
          ),
          const SizedBox(height: AppSpacing.xl),
          JzPrimaryButton(
            label: l.continueLabel,
            loading: loading,
            onPressed: () {
              if (_pin.text.length == 6) _verify(_pin.text);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          if (widget.args.purpose == OtpPurpose.signup)
            Center(
              child: TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final message = l.codeResent;
                  final ok = await ref
                      .read(authControllerProvider.notifier)
                      .resendSignupOtp(widget.args.email);
                  if (ok) {
                    messenger
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(message)));
                  }
                },
                child: Text(l.resendCode),
              ),
            ),
        ],
      ),
    );
  }
}
