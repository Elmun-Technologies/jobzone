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

/// Pay basis ("Оплата"): what the salary is per.
String? payTypeLabel(BuildContext c, String? wire) => switch (wire) {
  'hour' => c.l10n.payHour,
  'day' => c.l10n.payDay,
  'week' => c.l10n.payWeek,
  'month' => c.l10n.payMonth,
  'year' => c.l10n.payYear,
  'shift' => c.l10n.payShift,
  'task' => c.l10n.payTask,
  _ => null,
};

/// Payout frequency ("Частота выплат").
String? payoutFrequencyLabel(BuildContext c, String? wire) => switch (wire) {
  'monthly' => c.l10n.payoutMonthly,
  'biweekly' => c.l10n.payoutBiweekly,
  'weekly' => c.l10n.payoutWeekly,
  'daily' => c.l10n.payoutDaily,
  _ => null,
};
