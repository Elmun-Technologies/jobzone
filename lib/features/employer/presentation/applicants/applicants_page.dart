import 'package:flutter/material.dart';

import '../../../../localization/l10n_extension.dart';
import '../widgets/employer_placeholder.dart';

/// Cross-job applicant inbox for the employer, built in a later phase.
class ApplicantsPage extends StatelessWidget {
  const ApplicantsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EmployerPlaceholder(
      title: context.l10n.navApplicants,
      icon: Icons.people_outline_rounded,
    );
  }
}
