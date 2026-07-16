import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/auth_repository.dart';

// Nonce charset from Apple's "Sign in with Apple" reference (URL-safe,
// no ambiguous glyphs). 32 chars gives >190 bits of entropy — well beyond
// the 128 bits Apple recommends.
const String _nonceCharset =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';

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
  Future<void> signInWithApple() async {
    // Web / Android → browser OAuth via Supabase. Android doesn't need SIWA
    // (Apple's guideline is iOS-only), but exposing it there keeps a single
    // "sign in with Apple" account portable across the user's devices.
    if (kIsWeb || (!Platform.isIOS && !Platform.isMacOS)) {
      await _auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: kIsWeb ? null : 'io.jobzone.jobzone://login-callback',
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
      return;
    }
    // iOS / macOS → native SIWA. Apple wants the SHA-256 of a raw nonce,
    // Supabase wants both the raw nonce (for its own replay check) and the
    // id_token minted by Apple. Generate one raw nonce, hash it, hand the
    // hash to Apple, then pass raw + id_token to Supabase.
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );
    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException(
        'Apple did not return an identityToken',
        statusCode: '400',
      );
    }
    await _auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  String _generateNonce([int length = 32]) {
    final random = Random.secure();
    return List.generate(
      length,
      (_) => _nonceCharset[random.nextInt(_nonceCharset.length)],
    ).join();
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
