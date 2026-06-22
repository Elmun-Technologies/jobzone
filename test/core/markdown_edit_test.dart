import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/core/utils/markdown_edit.dart';

void main() {
  group('mdWrap', () {
    test('wraps a selection with the marker', () {
      final r = mdWrap(
        'hello world',
        const TextSelection(baseOffset: 6, extentOffset: 11),
        '**',
      );
      expect(r.text, 'hello **world**');
      expect(r.selection.baseOffset, 'hello **world**'.length);
    });

    test('inserts an empty pair with the caret between', () {
      final r = mdWrap('ab', const TextSelection.collapsed(offset: 1), '*');
      expect(r.text, 'a**b');
      expect(r.selection.baseOffset, 2);
    });
  });

  group('mdLinePrefix', () {
    test('prefixes the first line', () {
      final r = mdLinePrefix(
        'abc',
        const TextSelection.collapsed(offset: 0),
        '- ',
      );
      expect(r.text, '- abc');
    });

    test('prefixes the line containing the caret', () {
      final r = mdLinePrefix(
        'a\nb',
        const TextSelection.collapsed(offset: 2),
        '- ',
      );
      expect(r.text, 'a\n- b');
    });
  });
}
