import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository_impl.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';

/// Drives auth actions and exposes their progress as an [AsyncValue]. On
/// failure the error is a normalized [AuthFailure]. Each action returns a bool
/// so the UI can decide whether to navigate.
class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<bool> signIn({required String email, required String password}) =>
      _run(() => _repo.signInWithPassword(email: email, password: password));

  Future<bool> signInWithGoogle() => _run(_repo.signInWithGoogle);

  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) => _run(
    () => _repo.signUp(email: email, password: password, fullName: fullName),
  );

  Future<bool> verifySignup({required String email, required String token}) =>
      _run(
        () => _repo.verifyOtp(
          email: email,
          token: token,
          purpose: OtpPurpose.signup,
        ),
      );

  Future<bool> verifyRecovery({required String email, required String token}) =>
      _run(
        () => _repo.verifyOtp(
          email: email,
          token: token,
          purpose: OtpPurpose.recovery,
        ),
      );

  Future<bool> resendSignupOtp(String email) =>
      _run(() => _repo.resendSignupOtp(email));

  Future<bool> sendPasswordReset(String email) =>
      _run(() => _repo.resetPasswordForEmail(email));

  Future<bool> updatePassword(String password) =>
      _run(() => _repo.updatePassword(password));

  Future<bool> signOut() => _run(_repo.signOut);

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      state = AsyncError(AuthFailure.from(error), stack);
      return false;
    }
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
