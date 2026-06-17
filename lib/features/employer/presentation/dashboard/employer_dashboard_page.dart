import 'package:flutter/material.dart';

import '../../../../localization/l10n_extension.dart';
import '../widgets/employer_placeholder.dart';

/// Employer home: hiring stats + recent activity (built in a later phase).
class EmployerDashboardPage extends StatelessWidget {
  const EmployerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EmployerPlaceholder(
      title: context.l10n.navDashboard,
      icon: Icons.dashboard_outlined,
    );
  }
}
