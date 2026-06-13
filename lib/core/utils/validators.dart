/// Stateless input validation helpers. Pages pair these with localized
/// messages from `context.l10n`.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool isEmail(String value) => _email.hasMatch(value.trim());

  static bool isStrongEnough(String value) => value.length >= 8;

  static bool isNotBlank(String? value) =>
      value != null && value.trim().isNotEmpty;
}
