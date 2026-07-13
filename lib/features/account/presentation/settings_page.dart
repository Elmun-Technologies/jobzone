import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.settings),
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
                  _Tile(
                    icon: Icons.notifications_none_rounded,
                    label: l.notificationSettings,
                    onTap: () =>
                        context.push(Routes.accountNotificationSettings),
                  ),
                  _Tile(
                    icon: Icons.lock_outline_rounded,
                    label: l.passwordManager,
                    onTap: () => context.push(Routes.accountPassword),
                  ),
                  _Tile(
                    icon: Icons.delete_outline_rounded,
                    label: l.deleteAccount,
                    onTap: () => _confirmDelete(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Account deletion isn't implemented yet (it needs a service-role edge
  // function to remove the auth user). Showing the real "this permanently
  // deletes your data" confirm copy here — and then silently doing nothing —
  // would mislead the user into thinking the action succeeded. Say plainly
  // that it isn't available instead of presenting a destructive dialog with
  // no effect.
  void _confirmDelete(BuildContext context) {
    final l = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.deleteAccountUnavailable)));
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: Text(label, style: context.text.bodyLarge)),
            Icon(Icons.chevron_right_rounded, color: colors.primary),
          ],
        ),
      ),
    );
  }
}
