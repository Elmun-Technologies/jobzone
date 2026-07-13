/// Stateless input validation helpers. Pages pair these with localized
/// messages from `context.l10n`.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool isEmail(String value) => _email.hasMatch(value.trim());

  static bool isStrongEnough(String value) => value.length >= 8;

  static bool isNotBlank(String? value) =>
      value != null && value.trim().isNotEmpty;

  /// Normalizes a typed phone number to E.164 ("+998901234567"), or null when
  /// it can't be one. Accepts spaces/dashes/parentheses, an international
  /// "00" prefix, and a bare country-code form like "998901234567".
  static String? e164Phone(String raw) {
    var v = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (v.startsWith('00')) v = '+${v.substring(2)}';
    if (!v.startsWith('+') && v.length >= 11) v = '+$v';
    return RegExp(r'^\+\d{9,15}$').hasMatch(v) ? v : null;
  }

  /// E.164 for a phone entered with a fixed "+998" prefix: the caller passes
  /// only the national part (any spacing), and it must be exactly nine digits.
  /// Returns "+998901234567" or null. Used by the phone sign-in screen, where
  /// the "+998" is shown outside the field so the visitor types only their
  /// number.
  static String? uzLocalPhoneE164(String localPart) {
    final digits = localPart.replaceAll(RegExp(r'\D'), '');
    return digits.length == 9 ? '+998$digits' : null;
  }
}
