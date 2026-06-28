import 'package:flutter/widgets.dart';

import '../../../../localization/l10n_extension.dart';
import '../../domain/job_language.dart';

/// Localized labels for job attribute wire values (shared by cards & details).
String? jobTypeLabel(BuildContext c, String? wire) => switch (wire) {
  'full_time' => c.l10n.jobTypeFullTime,
  'part_time' => c.l10n.jobTypePartTime,
  'contract' => c.l10n.jobTypeContract,
  'internship' => c.l10n.jobTypeInternship,
  'temporary' => c.l10n.jobTypeTemporary,
  'rotational' => c.l10n.jobTypeRotational,
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

/// Localized salary-period suffix (e.g. "/month", "/soat"). Null when no period.
String? salaryPeriodLabel(BuildContext c, String? wire) => switch (wire) {
  'hour' => c.l10n.perHour,
  'day' => c.l10n.perDay,
  'week' => c.l10n.perWeek,
  'month' => c.l10n.perMonth,
  'year' => c.l10n.perYear,
  'shift' => c.l10n.perShift,
  'task' => c.l10n.perTask,
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

/// Work schedule pattern ("График работы").
String? schedulePatternLabel(BuildContext c, String? wire) => switch (wire) {
  '6_1' => '6/1',
  '5_2' => '5/2',
  '4_4' => '4/4',
  '2_2' => '2/2',
  'custom' => c.l10n.schedCustom,
  _ => null,
};

/// Employment formalization ("Оформление сотрудника").
String? formalizationLabel(BuildContext c, String? wire) => switch (wire) {
  'employment_contract' => c.l10n.formEmploymentContract,
  'gph' => c.l10n.formGph,
  'self_employed' => c.l10n.formSelfEmployed,
  'none' => c.l10n.formNone,
  _ => null,
};

const _kLanguageNames = {
  'uz': 'Oʻzbekcha',
  'ru': 'Русский',
  'en': 'English',
  'kk': 'Қазақша',
  'tr': 'Türkçe',
  'ar': 'العربية',
  'ko': '한국어',
  'zh': '中文',
  'de': 'Deutsch',
};

/// A required language as a display chip, e.g. "English · B2" / "Русский · Ona".
String jobLanguageLabel(BuildContext c, JobLanguage lang) {
  final name = _kLanguageNames[lang.code] ?? lang.code.toUpperCase();
  final level = lang.level == 'native'
      ? c.l10n.cefrNative
      : lang.level.toUpperCase();
  return '$name · $level';
}
