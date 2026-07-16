/// Purpose of an emailed one-time code.
enum OtpPurpose { signup, recovery }

/// Auth actions the app needs. Implemented over Supabase in the data layer;
/// controllers depend on this interface so they're testable with a fake.
abstract interface class AuthRepository {
  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  /// Starts the Google OAuth flow (redirect on web, external browser on
  /// mobile). Requires the Google provider to be enabled in Supabase Auth.
  Future<void> signInWithGoogle();

  /// Starts the Apple sign-in flow. On iOS/macOS this uses Apple's native
  /// AuthenticationServices SDK (App Store Guideline 4.8 — offering Google
  /// without Apple = automatic rejection). On Android + web falls back to
  /// Supabase's browser OAuth. Requires the Apple provider to be enabled
  /// in Supabase Auth (Services ID + Sign in with Apple key).
  Future<void> signInWithApple();

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

  /// Sends a one-time code to [phone] (E.164). Delivery goes through the
  /// project's Send-SMS auth hook — for Yolla that's a Telegram message, not
  /// an SMS. Creates the account on first use (sign-in and sign-up are the
  /// same flow).
  Future<void> sendPhoneOtp(String phone);

  /// Verifies the phone code; Supabase mints the session on success.
  Future<void> verifyPhoneOtp({required String phone, required String token});

  /// Starts verifying a phone for the CURRENTLY signed-in user (e.g. a Google
  /// account adding its number): sets a pending phone change and sends the OTP
  /// via the Telegram Send-SMS hook. Unlike [sendPhoneOtp] this never creates a
  /// new session — it attaches the phone to the existing account.
  Future<void> startPhoneChange(String phone);

  /// Confirms the pending phone change with [token]; on success the user's
  /// phone is confirmed in Supabase Auth (`phone_confirmed_at`).
  Future<void> verifyPhoneChange({
    required String phone,
    required String token,
  });

  Future<void> resetPasswordForEmail(String email);

  Future<void> updatePassword(String newPassword);

  Future<void> signOut();
}
