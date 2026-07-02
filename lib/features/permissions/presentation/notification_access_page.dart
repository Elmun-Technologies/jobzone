import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../app/router/routes.dart';
import '../../../localization/l10n_extension.dart';
import '../../auth/application/session_flags.dart';
import '../data/permission_service.dart';
import 'widgets/permission_scaffold.dart';

/// Final setup step. Granting/skipping notifications completes onboarding and
/// enters the app.
class NotificationAccessPage extends ConsumerWidget {
  const NotificationAccessPage({super.key});

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    // Local flag + profiles.onboarding_complete, so the next sign-in on any
    // device skips the setup chain.
    await completeProfileSetup(ref);
    if (context.mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return PermissionScaffold(
      icon: IconsaxPlusBold.notification,
      title: l.permNotifTitle,
      body: l.permNotifBody,
      primaryLabel: l.allowNotification,
      onPrimary: () async {
        await ref.read(permissionServiceProvider).requestNotifications();
        if (context.mounted) await _finish(context, ref);
      },
      secondaryLabel: l.maybeLater,
      onSecondary: () => _finish(context, ref),
    );
  }
}
