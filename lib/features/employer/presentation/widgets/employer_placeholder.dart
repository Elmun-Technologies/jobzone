import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';

/// Shared body for the employer tab pages whose full screens land in later
/// phases. A centered tab title plus a friendly "coming soon" empty state, with
/// no back button (these are shell tabs, not pushed routes).
class EmployerPlaceholder extends StatelessWidget {
  const EmployerPlaceholder({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(child: Text(title, style: context.text.titleLarge)),
            ),
            Expanded(
              child: JzEmptyState(
                icon: icon,
                title: l.comingSoon,
                message: l.comingSoonBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
