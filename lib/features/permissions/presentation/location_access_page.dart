import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../app/router/routes.dart';
import '../../../localization/l10n_extension.dart';
import '../data/permission_service.dart';
import 'widgets/permission_scaffold.dart';

class LocationAccessPage extends ConsumerWidget {
  const LocationAccessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return PermissionScaffold(
      icon: IconsaxPlusBold.location,
      title: l.permLocationTitle,
      body: l.permLocationBody,
      primaryLabel: l.allowLocationAccess,
      onPrimary: () async {
        await ref.read(permissionServiceProvider).requestLocation();
        if (context.mounted) context.push(Routes.permNotifications);
      },
      secondaryLabel: l.enterManually,
      onSecondary: () => context.push(Routes.permLocationManual),
    );
  }
}
