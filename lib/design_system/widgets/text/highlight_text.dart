import 'package:flutter/material.dart';

/// Renders text where segments wrapped in asterisks are painted in
/// [highlightColor] — e.g. `Finding *Your Perfect Career* Path` shows the
/// middle span in the brand color. Used for the two-tone headings in the
/// Figma design; the marker lives in the localized string so translators
/// choose which words to emphasize.
class HighlightText extends StatelessWidget {
  const HighlightText(
    this.text, {
    super.key,
    required this.style,
    required this.highlightColor,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final Color highlightColor;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final parts = text.split('*');
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (var i = 0; i < parts.length; i++)
            TextSpan(
              text: parts[i],
              // Odd segments were between asterisks → highlighted.
              style: i.isOdd ? TextStyle(color: highlightColor) : null,
            ),
        ],
      ),
      textAlign: textAlign,
    );
  }
}
