import 'package:flutter/material.dart';

import '../../../../localization/l10n_extension.dart';
import '../widgets/employer_placeholder.dart';

/// The employer's own company profile management, built in a later phase.
class CompanyManagePage extends StatelessWidget {
  const CompanyManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return EmployerPlaceholder(
      title: context.l10n.navCompany,
      icon: Icons.business_outlined,
    );
  }
}
