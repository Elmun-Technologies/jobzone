import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/providers/app_flags.dart';
import '../data/permission_service.dart';
import 'widgets/permission_scaffold.dart';

/// Final setup step. Granting/skipping notifications completes onboarding and
/// enters the app.
class NotificationAccessPage extends ConsumerWidget {
  const NotificationAccessPage({super.key});

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    await ref.read(appFlagsProvider.notifier).setProfileComplete(true);
    if (context.mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return PermissionScaffold(
      icon: Icons.notifications_active_outlined,
      title: l.permNotifTitle,
      body: l.permNotifBody,
      primaryLabel: l.allow,
      onPrimary: () async {
        await ref.read(permissionServiceProvider).requestNotifications();
        if (context.mounted) await _finish(context, ref);
      },
      skipLabel: l.skip,
      onSkip: () => _finish(context, ref),
    );
  }
}
