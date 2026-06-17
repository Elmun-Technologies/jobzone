import 'package:flutter/material.dart';

import '../../../../localization/l10n_extension.dart';
import '../widgets/employer_placeholder.dart';

/// The employer's posted jobs (open / draft / closed), built in a later phase.
class MyJobsPage extends StatelessWidget {
  const MyJobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EmployerPlaceholder(
      title: context.l10n.navMyJobs,
      icon: Icons.work_outline_rounded,
    );
  }
}
