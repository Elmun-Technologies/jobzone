import 'package:flutter/services.dart';

/// Formats the *national* part of an Uzbek number as the visitor types, so the
/// field reads "90 123 45 67" while a fixed "+998" prefix lives outside it. The
/// visitor never types (or can delete) the country code — see [PhoneSignInPage].
///
/// Digits are grouped 2-3-2-2 and capped at nine. A pasted "+998…"/"998…" or a
/// leading zero is tolerated: the country code and the trunk "0" are stripped so
/// paste-in still lands on the nine national digits.
class UzLocalPhoneFormatter extends TextInputFormatter {
  const UzLocalPhoneFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    // Tolerate a pasted country code so "+998 90…" collapses to the 9 national
    // digits rather than overflowing the cap.
    if (digits.length > 9 && digits.startsWith('998')) {
      digits = digits.substring(3);
    }
    // A leading trunk "0" (some people type "090…") isn't part of E.164.
    if (digits.length > 9 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.length > 9) digits = digits.substring(0, 9);

    final formatted = _group(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// "901234567" -> "90 123 45 67".
  static String _group(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5 || i == 7) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
