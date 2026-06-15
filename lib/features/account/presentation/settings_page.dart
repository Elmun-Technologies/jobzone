import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/config/env.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../auth/application/auth_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final themeMode = ref.watch(themeModeControllerProvider);

    return JzScaffold(
      title: l.settings,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
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
          const SizedBox(height: AppSpacing.lg),
          _Tile(
            icon: Icons.language_rounded,
            label: l.language,
            onTap: () => context.push(Routes.accountLanguage),
          ),
          _Tile(
            icon: Icons.badge_outlined,
            label: l.personalInformation,
            onTap: () => context.push(Routes.accountPersonalInfo),
          ),
          _Tile(
            icon: Icons.work_outline_rounded,
            label: l.jobSeekingStatus,
            onTap: () => context.push(Routes.accountSeekingStatus),
          ),
          _Tile(
            icon: Icons.notifications_none_rounded,
            label: l.notificationSettings,
            onTap: () => context.push(Routes.accountNotificationSettings),
          ),
          _Tile(
            icon: Icons.lock_outline_rounded,
            label: l.passwordManager,
            onTap: () => context.push(Routes.accountPassword),
          ),
          const Divider(height: AppSpacing.xl),
          _Tile(
            icon: Icons.logout_rounded,
            label: l.logOut,
            danger: true,
            onTap: () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.logOut),
        content: Text(l.logOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.logOut),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    if (Env.hasSupabase) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
    if (context.mounted) context.go(Routes.welcome);
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? context.colors.danger : context.colors.textPrimary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label, style: context.text.bodyLarge?.copyWith(color: color)),
      trailing: danger ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
