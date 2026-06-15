import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';

/// Profile tab — also the account/settings hub. Demonstrates live theming and
/// the entry point to the Language screen.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final colors = context.colors;
    final themeMode = ref.watch(themeModeControllerProvider);

    return JzScaffold(
      title: l.navProfile,
      showBack: false,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: colors.chipBackground,
                child: Icon(
                  Icons.person_rounded,
                  size: 32,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your name', style: context.text.titleMedium),
                    Text(
                      'Open to work',
                      style: context.text.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l.appearance, style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l.themeSystem),
              ),
              ButtonSegment(value: ThemeMode.light, label: Text(l.themeLight)),
              ButtonSegment(value: ThemeMode.dark, label: Text(l.themeDark)),
            ],
            selected: {themeMode},
            onSelectionChanged: (s) => ref
                .read(themeModeControllerProvider.notifier)
                .setThemeMode(s.first),
          ),
          const SizedBox(height: AppSpacing.xl),
          _Tile(
            icon: Icons.account_circle_outlined,
            label: l.yourProfile,
            onTap: () => context.push(Routes.yourProfile),
          ),
          _Tile(
            icon: Icons.language_rounded,
            label: l.language,
            onTap: () => context.push(Routes.accountLanguage),
          ),
          _Tile(
            icon: Icons.badge_outlined,
            label: 'Personal Information',
            onTap: () => context.push(Routes.accountPersonalInfo),
          ),
          _Tile(
            icon: Icons.description_outlined,
            label: l.myApplications,
            onTap: () => context.push(Routes.accountApplications),
          ),
          _Tile(
            icon: Icons.bookmark_border_rounded,
            label: l.bookmarks,
            onTap: () => context.push(Routes.bookmarks),
          ),
          _Tile(
            icon: Icons.notifications_none_rounded,
            label: l.notificationSettings,
            onTap: () => context.push(Routes.accountNotificationSettings),
          ),
          _Tile(
            icon: Icons.settings_outlined,
            label: l.settings,
            onTap: () => context.push(Routes.accountSettings),
          ),
          _Tile(
            icon: Icons.help_outline_rounded,
            label: 'Help Center',
            onTap: () => context.push(Routes.accountHelp),
          ),
          _Tile(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () => context.push(Routes.accountPrivacy),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: context.colors.textPrimary),
      title: Text(label, style: context.text.bodyLarge),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
