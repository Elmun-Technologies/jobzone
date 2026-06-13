import 'package:flutter/widgets.dart';

import '../../../../localization/l10n_extension.dart';
import '../../domain/auth_failure.dart';

/// Maps an [AuthFailure] (or any error) to a localized, user-facing message.
String authFailureMessage(BuildContext context, Object error) {
  final l = context.l10n;
  final failure = error is AuthFailure ? error : AuthFailure.from(error);
  return switch (failure) {
    InvalidCredentialsFailure() => l.errInvalidCredentials,
    EmailInUseFailure() => l.errEmailInUse,
    WeakPasswordFailure() => l.errWeakPassword,
    InvalidOtpFailure() => l.errInvalidOtp,
    NetworkAuthFailure() => l.errNetwork,
    UnknownAuthFailure(:final message) => message ?? l.errUnknown,
  };
}
