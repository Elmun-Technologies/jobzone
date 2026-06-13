import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../localization/locale_controller.dart';

/// Runtime language switcher. Selecting a locale rebuilds the whole app via the
/// `localeControllerProvider` watched by MaterialApp.router — no restart needed.
class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final current = ref.watch(localeControllerProvider);

    Widget option(String title, Locale? locale) {
      final selected = current?.languageCode == locale?.languageCode;
      return ListTile(
        title: Text(title),
        trailing: selected
            ? Icon(Icons.check_circle_rounded, color: context.colors.primary)
            : const Icon(Icons.circle_outlined),
        onTap: () =>
            ref.read(localeControllerProvider.notifier).setLocale(locale),
      );
    }

    return JzScaffold(
      title: l.language,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          option(l.themeSystem, null),
          const Divider(height: 1),
          option(l.langEnglish, const Locale('en')),
          option(l.langRussian, const Locale('ru')),
          option(l.langUzbek, const Locale('uz')),
        ],
      ),
    );
  }
}
