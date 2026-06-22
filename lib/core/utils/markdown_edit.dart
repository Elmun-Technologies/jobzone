import 'package:flutter/widgets.dart';

/// Result of a markdown toolbar action: the new text and where to put the caret.
class MarkdownEdit {
  const MarkdownEdit(this.text, this.selection);
  final String text;
  final TextSelection selection;
}

int _start(String text, TextSelection s) => s.start < 0 ? text.length : s.start;
int _end(String text, TextSelection s) => s.end < 0 ? text.length : s.end;

/// Wraps the current selection with [marker] (`**` bold, `*` italic). With no
/// selection, inserts the marker pair and places the caret between them.
MarkdownEdit mdWrap(String text, TextSelection sel, String marker) {
  final start = _start(text, sel);
  final end = _end(text, sel);
  final selected = text.substring(start, end);
  final newText = text.replaceRange(start, end, '$marker$selected$marker');
  final caret = selected.isEmpty
      ? start + marker.length
      : start + marker.length * 2 + selected.length;
  return MarkdownEdit(newText, TextSelection.collapsed(offset: caret));
}

/// Prefixes the line containing the selection start with [prefix] (`- ` /
/// `1. `) to make a list item.
MarkdownEdit mdLinePrefix(String text, TextSelection sel, String prefix) {
  final start = _start(text, sel);
  final lineStart = start == 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1;
  final newText = text.replaceRange(lineStart, lineStart, prefix);
  return MarkdownEdit(
    newText,
    TextSelection.collapsed(offset: _end(text, sel) + prefix.length),
  );
}
