import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ensures the en/ru/uz ARB files define exactly the same message keys, so no
/// locale silently falls back. Metadata keys (`@@locale`, `@<key>`) are ignored.
void main() {
  String rawOf(String locale) =>
      File('lib/localization/l10n/app_$locale.arb').readAsStringSync();

  Set<String> keysOf(String locale) {
    final map = jsonDecode(rawOf(locale)) as Map<String, dynamic>;
    return map.keys.where((k) => !k.startsWith('@')).toSet();
  }

  // jsonDecode silently collapses duplicate keys (last value wins), so a
  // repeated key would pass the set-based parity check below while quietly
  // dropping a translation at codegen time. Parse the raw text instead: every
  // top-level entry is one `"key": ...` line (2-space indent, one per line
  // throughout these files), so a regex catches duplicates jsonDecode can't.
  List<String> rawTopLevelKeys(String locale) {
    final keyLine = RegExp(r'^\s{2}"([^"]+)":');
    return rawOf(locale)
        .split('\n')
        .map((line) => keyLine.firstMatch(line)?.group(1))
        .whereType<String>()
        .where((k) => !k.startsWith('@'))
        .toList();
  }

  test('no locale has a duplicate top-level key', () {
    for (final locale in ['en', 'ru', 'uz']) {
      final keys = rawTopLevelKeys(locale);
      final seen = <String>{};
      final dupes = <String>{};
      for (final k in keys) {
        if (!seen.add(k)) dupes.add(k);
      }
      expect(dupes, isEmpty, reason: '$locale.arb has duplicate keys: $dupes');
    }
  });

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
