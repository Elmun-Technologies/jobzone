import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';

import '../../../../core/utils/validators.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/presentation/util/auth_failure_message.dart';
import '../../../auth/presentation/util/uz_phone_input_formatter.dart';
import '../../data/profile_repository.dart';

/// Opens the phone-verification sheet for the signed-in user. Returns `true`
/// when the phone was verified so the caller can refresh the profile.
Future<bool?> showPhoneVerifySheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => const _PhoneVerifySheet(),
  );
}

/// Two-stage phone verification for an already-signed-in account (e.g. a Google
/// user adding their number): enter the number → a one-time code is sent to
/// Telegram (via the Send-SMS hook, `updateUser(phone:)`) → enter the code →
/// the phone is confirmed in Supabase Auth and `confirm_phone` stamps the
/// profile's verified badge. Distinct from the sign-in OTP flow, which mints a
/// new session.
class _PhoneVerifySheet extends ConsumerStatefulWidget {
  const _PhoneVerifySheet();

  @override
  ConsumerState<_PhoneVerifySheet> createState() => _PhoneVerifySheetState();
}

class _PhoneVerifySheetState extends ConsumerState<_PhoneVerifySheet> {
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
    final normalized = Validators.uzLocalPhoneE164(_phone.text);
    if (normalized == null) {
      showErrorSnack(context, l.valPhoneRequired);
      return;
    }
    final ok = await ref
        .read(authControllerProvider.notifier)
        .startPhoneChange(normalized);
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
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .verifyPhoneChange(phone: phone, token: code);
    if (!mounted) return;
    if (!ok) {
      showErrorSnack(
        context,
        authFailureMessage(context, ref.read(authControllerProvider).error!),
      );
      return;
    }
    // Phone is now confirmed in Auth — stamp the profile's verified badge.
    try {
      await ref.read(profileRepositoryProvider).confirmPhone();
    } catch (_) {
      // The phone is confirmed even if the badge write hiccups; the next
      // profile load reconciles it. Don't block the success path.
    }
    if (!mounted) return;
    Navigator.pop(context, true);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.phoneVerifiedToast)));
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

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l.verifyPhone,
            textAlign: TextAlign.center,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _sentTo == null
                ? l.phoneSignInSubtitle
                : '${l.phoneCodeSubtitle}\n$_sentTo',
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_sentTo == null) ...[
            JzTextField(
              label: l.phoneNumber,
              hint: '90 123 45 67',
              controller: _phone,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumberNational],
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
            const SizedBox(height: AppSpacing.lg),
            JzPrimaryButton(
              label: l.sendCode,
              loading: loading,
              onPressed: _sendCode,
            ),
          ] else ...[
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
            const SizedBox(height: AppSpacing.lg),
            JzPrimaryButton(
              label: l.verify,
              loading: loading,
              onPressed: () {
                if (_pin.text.length == 6) _verify(_pin.text);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: () => setState(() {
                  _sentTo = null;
                  _pin.clear();
                }),
                child: Text(l.changePhoneNumber),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
