import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../localization/locale_controller.dart';

/// Runtime language switcher. Selecting a locale rebuilds the app via
/// `localeControllerProvider`. The app ships en/ru/uz translations.
class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final current = ref.watch(localeControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.language),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  for (final (title, code) in [
                    (l.langEnglish, 'en'),
                    (l.langRussian, 'ru'),
                    (l.langUzbek, 'uz'),
                  ])
                    _RadioRow(
                      label: title,
                      selected: current?.languageCode == code,
                      onTap: () => ref
                          .read(localeControllerProvider.notifier)
                          .setLocale(Locale(code)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            JzRadio(selected: selected),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: context.text.bodyLarge)),
          ],
        ),
      ),
    );
  }
}
