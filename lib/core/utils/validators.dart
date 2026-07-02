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
}
