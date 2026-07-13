import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';

/// Labelled text field built on the shared [InputDecorationTheme].
class JzTextField extends StatelessWidget {
  const JzTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.prefix,
    this.suffixIcon,
    this.onChanged,
    this.validator,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.maxLines = 1,
    this.minLines,
    this.readOnly = false,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;

  /// A fixed, always-visible adornment shown before the input (e.g. a "+998"
  /// dial code). Takes the leading slot, so pass either this or [prefixIcon].
  final Widget? prefix;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final int? maxLines;
  final int? minLines;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: context.text.labelLarge),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          decoration: InputDecoration(
            hintText: hint,
            // The leading slot holds either a fixed adornment (e.g. "+998") or
            // an icon; the adornment gets a tight constraint so it sits snug
            // against the input instead of the icon's default 48px box.
            prefixIcon:
                prefix ?? (prefixIcon == null ? null : Icon(prefixIcon)),
            prefixIconConstraints: prefix == null
                ? null
                : const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
