import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../design_system/design_system.dart';

/// Tappable field that opens a date picker and shows the chosen month/year.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.hint,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool enabled;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = value == null
        ? (hint ?? '—')
        : DateFormat.yMMM().format(value!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: enabled ? () => _pick(context) : null,
          child: InputDecorator(
            decoration: const InputDecoration(),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    text,
                    style: context.text.bodyLarge?.copyWith(
                      color: value == null || !enabled
                          ? colors.textSecondary
                          : colors.textPrimary,
                    ),
                  ),
                ),
                if (value != null && enabled)
                  GestureDetector(
                    onTap: () => onChanged(null),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(1960),
      lastDate: DateTime(now.year + 10),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) onChanged(picked);
  }
}
