/// Purpose of an emailed one-time code.
enum OtpPurpose { signup, recovery }

/// Auth actions the app needs. Implemented over Supabase in the data layer;
/// controllers depend on this interface so they're testable with a fake.
abstract interface class AuthRepository {
  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
  });

  Future<void> verifyOtp({
    required String email,
    required String token,
    required OtpPurpose purpose,
  });

  Future<void> resendSignupOtp(String email);

  Future<void> resetPasswordForEmail(String email);

  Future<void> updatePassword(String newPassword);

  Future<void> signOut();
}
