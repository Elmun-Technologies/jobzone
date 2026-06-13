import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

/// Shared scaffold for a single preference-setup step: title app bar, an
/// optional subtitle, the step body, and a sticky primary "next" button.
class PreferenceStepScaffold extends StatelessWidget {
  const PreferenceStepScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    required this.nextLabel,
    required this.onNext,
    this.nextEnabled = true,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final String nextLabel;
  final VoidCallback onNext;
  final bool nextEnabled;

  @override
  Widget build(BuildContext context) {
    return JzScaffold(
      title: title,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null) ...[
              Text(
                subtitle!,
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Expanded(child: SingleChildScrollView(child: child)),
            const SizedBox(height: AppSpacing.lg),
            JzPrimaryButton(
              label: nextLabel,
              onPressed: nextEnabled ? onNext : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Wrap of filter chips for selecting multiple options. `options` maps each
/// stored value (wire) to its localized label.
class MultiSelectChips extends StatelessWidget {
  const MultiSelectChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final Map<String, String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final entry in options.entries)
          FilterChip(
            label: Text(entry.value),
            selected: selected.contains(entry.key),
            onSelected: (_) => onToggle(entry.key),
          ),
      ],
    );
  }
}
