import 'package:flutter/material.dart';

import 'jz_text_field.dart';

/// Password field with a built-in show/hide eye toggle, matching the Figma
/// inputs (filled, label above, slashed-eye suffix).
class JzPasswordField extends StatefulWidget {
  const JzPasswordField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.textInputAction,
    this.onChanged,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  @override
  State<JzPasswordField> createState() => _JzPasswordFieldState();
}

class _JzPasswordFieldState extends State<JzPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return JzTextField(
      label: widget.label,
      hint: widget.hint,
      controller: widget.controller,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      obscureText: _obscure,
      suffixIcon: IconButton(
        splashRadius: 20,
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}
