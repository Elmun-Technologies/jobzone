import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../application/auth_controller.dart';
import '../util/auth_failure_message.dart';
import '../util/uz_phone_input_formatter.dart';
import '../widgets/auth_header.dart';

/// Phone sign-in/up. The one-time code is delivered as a **Telegram message**
/// (Telegram Gateway via the Send-SMS auth hook), not an SMS. One flow covers
/// both login and registration: a new phone gets an account and the router's
/// role/setup guards take over; a returning one is hydrated straight to its
/// shell by ChooseRolePage.
class PhoneSignInPage extends ConsumerStatefulWidget {
  const PhoneSignInPage({super.key});

  @override
  ConsumerState<PhoneSignInPage> createState() => _PhoneSignInPageState();
}

class _PhoneSignInPageState extends ConsumerState<PhoneSignInPage> {
  final _phone = TextEditingController();
  final _pin = TextEditingController();

  /// E.164 number the code was sent to; null while still on the phone stage.
  String? _sentTo;

  @override
  void dispose() {
    _phone.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final l = context.l10n;
    // The field holds only the national part; "+998" is fixed in the UI.
    final normalized = Validators.uzLocalPhoneE164(_phone.text);
    if (normalized == null) {
      showErrorSnack(context, l.valPhoneRequired);
      return;
    }
    final ok = await ref
        .read(authControllerProvider.notifier)
        .sendPhoneOtp(normalized);
    if (!mounted) return;
    if (ok) {
      setState(() => _sentTo = normalized);
    } else {
      showErrorSnack(
        context,
        authFailureMessage(context, ref.read(authControllerProvider).error!),
      );
    }
  }

  Future<void> _verify(String code) async {
    final phone = _sentTo;
    if (phone == null) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .verifyPhoneOtp(phone: phone, token: code);
    if (!mounted) return;
    if (ok) {
      // New accounts pick a role next; returning accounts are bounced onward
      // by the router once ChooseRolePage hydrates their finished profile.
      context.go(Routes.chooseRole);
    } else {
      showErrorSnack(
        context,
        authFailureMessage(context, ref.read(authControllerProvider).error!),
      );
    }
  }

  Future<void> _resend() async {
    final phone = _sentTo;
    if (phone == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.codeResent;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .sendPhoneOtp(phone);
    if (ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final loading = ref.watch(authControllerProvider).isLoading;

    final base = PinTheme(
      width: 46,
      height: 56,
      textStyle: context.text.headlineSmall,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          children: _sentTo == null
              ? [
                  AuthHeader(
                    title: l.phoneSignInTitle,
                    subtitle: l.phoneSignInSubtitle,
                    showBack: true,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  JzTextField(
                    label: l.phoneNumber,
                    hint: '90 123 45 67',
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [
                      AutofillHints.telephoneNumberNational,
                    ],
                    inputFormatters: const [UzLocalPhoneFormatter()],
                    prefix: Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.lg,
                        right: AppSpacing.sm,
                      ),
                      child: Text(
                        '+998',
                        style: context.text.bodyLarge?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  JzPrimaryButton(
                    label: l.sendCode,
                    loading: loading,
                    onPressed: _sendCode,
                  ),
                ]
              : [
                  AuthHeader(
                    title: l.verifyCodeTitle,
                    subtitle: '${l.phoneCodeSubtitle}\n*$_sentTo*',
                    showBack: true,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
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
                  Text(
                    l.didntReceiveOtp,
                    textAlign: TextAlign.center,
                    style: context.text.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Center(
                    child: GestureDetector(
                      onTap: _resend,
                      child: Text(
                        l.resendCode,
                        style: context.text.bodyMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _sentTo = null;
                        _pin.clear();
                      }),
                      child: Text(
                        l.changePhoneNumber,
                        style: context.text.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  JzPrimaryButton(
                    label: l.verify,
                    loading: loading,
                    onPressed: () {
                      if (_pin.text.length == 6) _verify(_pin.text);
                    },
                  ),
                ],
        ),
      ),
    );
  }
}
