import 'package:flutter/widgets.dart';

import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/enums/enums.dart';

String applicationStatusLabel(BuildContext c, ApplicationStatus s) =>
    switch (s) {
      ApplicationStatus.submitted => c.l10n.statusSubmitted,
      ApplicationStatus.viewed => c.l10n.statusViewed,
      ApplicationStatus.shortlisted => c.l10n.statusShortlisted,
      ApplicationStatus.interview => c.l10n.statusInterview,
      ApplicationStatus.offer => c.l10n.statusOffer,
      ApplicationStatus.rejected => c.l10n.statusRejected,
      ApplicationStatus.hired => c.l10n.statusHired,
      ApplicationStatus.withdrawn => c.l10n.statusWithdrawn,
    };

Color applicationStatusColor(BuildContext c, ApplicationStatus s) {
  final colors = c.colors;
  return switch (s) {
    ApplicationStatus.rejected || ApplicationStatus.withdrawn => colors.danger,
    ApplicationStatus.offer || ApplicationStatus.hired => colors.success,
    ApplicationStatus.interview ||
    ApplicationStatus.shortlisted => colors.primary,
    _ => colors.textSecondary,
  };
}
