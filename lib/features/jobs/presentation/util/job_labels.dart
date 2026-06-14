import 'package:flutter/widgets.dart';

import '../../../../localization/l10n_extension.dart';

/// Localized labels for job attribute wire values (shared by cards & details).
String? jobTypeLabel(BuildContext c, String? wire) => switch (wire) {
  'full_time' => c.l10n.jobTypeFullTime,
  'part_time' => c.l10n.jobTypePartTime,
  'contract' => c.l10n.jobTypeContract,
  'internship' => c.l10n.jobTypeInternship,
  'temporary' => c.l10n.jobTypeTemporary,
  _ => null,
};

String? workingModelLabel(BuildContext c, String? wire) => switch (wire) {
  'onsite' => c.l10n.wmOnsite,
  'remote' => c.l10n.wmRemote,
  'hybrid' => c.l10n.wmHybrid,
  _ => null,
};

String? experienceLabel(BuildContext c, String? wire) => switch (wire) {
  'entry' => c.l10n.expEntry,
  'mid' => c.l10n.expMid,
  'senior' => c.l10n.expSenior,
  'lead' => c.l10n.expLead,
  _ => null,
};
