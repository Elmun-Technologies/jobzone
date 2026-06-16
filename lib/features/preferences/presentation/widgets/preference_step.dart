import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

/// Shared scaffold for a preference-setup step (matches the Figma design):
/// a circular back button + progress bar + "step/total" counter, a centered
/// title, the step body, and a sticky primary "Next" button.
class PreferenceStepScaffold extends StatelessWidget {
  const PreferenceStepScaffold({
    super.key,
    required this.title,
    required this.step,
    required this.totalSteps,
    required this.child,
    required this.nextLabel,
    required this.onNext,
    this.nextEnabled = true,
  });

  final String title;
  final int step;
  final int totalSteps;
  final Widget child;
  final String nextLabel;
  final VoidCallback onNext;
  final bool nextEnabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  JzCircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: step / totalSteps,
                        minHeight: 6,
                        backgroundColor: colors.surfaceVariant,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    '$step/$totalSteps',
                    style: context.text.labelLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(child: SingleChildScrollView(child: child)),
              const SizedBox(height: AppSpacing.lg),
              JzPrimaryButton(
                label: nextLabel,
                onPressed: nextEnabled ? onNext : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vertical list of selectable option cards with a leading checkbox — the
/// reference's preference picker. `options` maps each stored value to its
/// localized label; multiple may be selected.
class OptionCheckList extends StatelessWidget {
  const OptionCheckList({
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
    return Column(
      children: [
        for (final entry in options.entries)
          _OptionTile(
            label: entry.value,
            selected: selected.contains(entry.key),
            onTap: () => onToggle(entry.key),
          ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected ? colors.primary : colors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                _CheckBox(selected: selected),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(label, style: context.text.bodyLarge)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? colors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: selected ? colors.primary : colors.border,
          width: 1.5,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 16, color: colors.onPrimary)
          : null,
    );
  }
}
