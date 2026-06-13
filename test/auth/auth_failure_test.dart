import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/auth/domain/auth_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AuthFailure.from', () {
    test('maps invalid credentials', () {
      final f = AuthFailure.from(
        const AuthException(
          'Invalid login credentials',
          code: 'invalid_credentials',
        ),
      );
      expect(f, isA<InvalidCredentialsFailure>());
    });

    test('maps email already in use', () {
      final f = AuthFailure.from(
        const AuthException(
          'User already registered',
          code: 'user_already_exists',
        ),
      );
      expect(f, isA<EmailInUseFailure>());
    });

    test('maps weak password', () {
      final f = AuthFailure.from(
        const AuthException(
          'Password should be at least 6 characters',
          code: 'weak_password',
        ),
      );
      expect(f, isA<WeakPasswordFailure>());
    });

    test('falls back to unknown', () {
      final f = AuthFailure.from(const AuthException('boom'));
      expect(f, isA<UnknownAuthFailure>());
    });

    test('passes an existing AuthFailure through unchanged', () {
      expect(
        AuthFailure.from(const NetworkAuthFailure()),
        isA<NetworkAuthFailure>(),
      );
    });
  });
}
