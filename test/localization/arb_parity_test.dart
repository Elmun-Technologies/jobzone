import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ensures the en/ru/uz ARB files define exactly the same message keys, so no
/// locale silently falls back. Metadata keys (`@@locale`, `@<key>`) are ignored.
void main() {
  Set<String> keysOf(String locale) {
    final file = File('lib/localization/l10n/app_$locale.arb');
    final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return map.keys.where((k) => !k.startsWith('@')).toSet();
  }

  test('ru and uz cover the same keys as en', () {
    final en = keysOf('en');
    final ru = keysOf('ru');
    final uz = keysOf('uz');

    expect(en, isNotEmpty);
    expect(ru.difference(en), isEmpty, reason: 'ru has keys missing from en');
    expect(
      en.difference(ru),
      isEmpty,
      reason: 'en keys missing from ru: ${en.difference(ru)}',
    );
    expect(
      en.difference(uz),
      isEmpty,
      reason: 'en keys missing from uz: ${en.difference(uz)}',
    );
    expect(uz.difference(en), isEmpty, reason: 'uz has keys missing from en');
  });
}
