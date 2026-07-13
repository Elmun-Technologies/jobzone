import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;
  GoTrueClient get _auth => _client.auth;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signInWithGoogle() async {
    await _auth.signInWithOAuth(
      OAuthProvider.google,
      // Web redirects within the current origin; mobile uses the app deep link.
      redirectTo: kIsWeb ? null : 'io.jobzone.jobzone://login-callback',
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    await _auth.signUp(
      email: email,
      password: password,
      data: fullName == null ? null : {'full_name': fullName},
    );
  }

  @override
  Future<void> verifyOtp({
    required String email,
    required String token,
    required OtpPurpose purpose,
  }) async {
    await _auth.verifyOTP(
      email: email,
      token: token,
      type: purpose == OtpPurpose.signup ? OtpType.signup : OtpType.recovery,
    );
  }

  @override
  Future<void> resendSignupOtp(String email) async {
    await _auth.resend(type: OtpType.signup, email: email);
  }

  @override
  Future<void> sendPhoneOtp(String phone) async {
    await _auth.signInWithOtp(phone: phone);
  }

  @override
  Future<void> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    await _auth.verifyOTP(phone: phone, token: token, type: OtpType.sms);
  }

  @override
  Future<void> startPhoneChange(String phone) async {
    // Attaches a pending phone to the signed-in user and triggers the OTP
    // (delivered to Telegram by the send-sms hook), without minting a session.
    await _auth.updateUser(UserAttributes(phone: phone));
  }

  @override
  Future<void> verifyPhoneChange({
    required String phone,
    required String token,
  }) async {
    await _auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.phoneChange,
    );
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
});
