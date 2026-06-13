import 'package:supabase_flutter/supabase_flutter.dart';

/// Domain-level auth errors, decoupled from Supabase. The presentation layer
/// maps each case to a localized message (see `auth_failure_message.dart`).
sealed class AuthFailure {
  const AuthFailure();

  /// Normalizes any thrown error (Supabase [AuthException], network, etc.).
  factory AuthFailure.from(Object error) {
    if (error is AuthFailure) return error;

    final raw = error.toString();
    if (raw.contains('SocketException') ||
        raw.contains('Failed host lookup') ||
        raw.contains('Connection') ||
        error is AuthRetryableFetchException) {
      return const NetworkAuthFailure();
    }

    if (error is AuthException) {
      final code = error.code;
      final msg = error.message.toLowerCase();
      if (code == 'invalid_credentials' || msg.contains('invalid login')) {
        return const InvalidCredentialsFailure();
      }
      if (code == 'user_already_exists' ||
          msg.contains('already registered') ||
          msg.contains('already been registered')) {
        return const EmailInUseFailure();
      }
      if (code == 'weak_password' || msg.contains('password should be')) {
        return const WeakPasswordFailure();
      }
      if (code == 'otp_expired' ||
          msg.contains('expired') ||
          msg.contains('invalid otp') ||
          msg.contains('token')) {
        return const InvalidOtpFailure();
      }
      return UnknownAuthFailure(error.message);
    }

    return UnknownAuthFailure(raw);
  }
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure();
}

class EmailInUseFailure extends AuthFailure {
  const EmailInUseFailure();
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure();
}

class InvalidOtpFailure extends AuthFailure {
  const InvalidOtpFailure();
}

class NetworkAuthFailure extends AuthFailure {
  const NetworkAuthFailure();
}

class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure(this.message);
  final String? message;
}
