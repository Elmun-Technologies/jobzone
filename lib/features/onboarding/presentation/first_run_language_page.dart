import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../localization/locale_controller.dart';
import '../../../shared/providers/app_flags.dart';

/// First-run language picker — the hop between onboarding and the welcome
/// screen. Selecting a language previews it live (the whole UI re-renders via
/// `localeControllerProvider`); "Continue" persists the choice so the router
/// guard never shows this screen again.
class FirstRunLanguagePage extends ConsumerStatefulWidget {
  const FirstRunLanguagePage({super.key});

  @override
  ConsumerState<FirstRunLanguagePage> createState() =>
      _FirstRunLanguagePageState();
}

class _FirstRunLanguagePageState extends ConsumerState<FirstRunLanguagePage> {
  // Default to Uzbek — the product's first language — until the user picks.
  late String _selected =
      ref.read(localeControllerProvider)?.languageCode ?? 'uz';

  void _select(String code) {
    setState(() => _selected = code);
    // Live preview: rebuild the app in the chosen language immediately.
    ref.read(localeControllerProvider.notifier).setLocale(Locale(code));
  }

  Future<void> _continue() async {
    // Cover the case where the user never tapped a row (keeps the default).
    await ref
        .read(localeControllerProvider.notifier)
        .setLocale(Locale(_selected));
    await ref.read(appFlagsProvider.notifier).markLanguageChosen();
    if (mounted) context.go(Routes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(Icons.translate_rounded, color: colors.onGold),
              ),
              const SizedBox(height: AppSpacing.lg),
              HighlightText(
                l.chooseLanguageTitle,
                highlightColor: colors.primary,
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.chooseLanguageSubtitle,
                style: context.text.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              for (final (label, code) in [
                (l.langUzbek, 'uz'),
                (l.langRussian, 'ru'),
                (l.langEnglish, 'en'),
              ]) ...[
                _LanguageTile(
                  label: label,
                  selected: _selected == code,
                  onTap: () => _select(code),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              const Spacer(),
              JzPrimaryButton(label: l.continueLabel, onPressed: _continue),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
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
    return Material(
      color: selected ? colors.accent.withValues(alpha: 0.12) : colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              JzRadio(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}
