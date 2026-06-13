import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../localization/l10n_extension.dart';

/// Stub used by routes whose full screen lands in a later phase. It keeps the
/// navigation graph complete and navigable today.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return JzScaffold(
      title: title,
      body: JzEmptyState(
        icon: Icons.construction_outlined,
        title: context.l10n.comingSoon,
        message: context.l10n.comingSoonBody,
      ),
    );
  }
}
