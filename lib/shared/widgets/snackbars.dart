import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/employer/data/employer_jobs_repository.dart';
import '../../localization/l10n_extension.dart';

void showErrorSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void showInfoSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Maps a caught [error] to a localized, user-safe message so raw
/// PostgrestException / Auth internals are never shown to users (uz/ru/en).
/// Falls back to a generic "something went wrong".
String localizedError(BuildContext context, Object error) {
  final l = context.l10n;
  if (error is NoCompanyError) return l.errNoCompany;
  if (error is PostgrestException) {
    switch (error.code) {
      case '23502': // not_null_violation — most commonly jobs.company_id
        if ((error.message).contains('company_id')) return l.errNoCompany;
        break;
      case '23505': // unique_violation
        return l.alreadyExists;
      case '42501': // insufficient_privilege (RLS denied)
        return l.notAllowed;
    }
  }
  // The real reason (undefined column from an un-applied migration → 42703 /
  // PGRST204, a check/enum violation, a function 500…) is intentionally not
  // shown to users, but log it so it's visible in Logcat during dev/debug —
  // otherwise "something went wrong" is undiagnosable from the screen.
  _logError(error);
  return l.errUnknown;
}

/// Dev-only breadcrumb for errors we deliberately show as a generic message.
/// Includes the Postgrest code/details when present so a failed publish/write
/// can be traced without exposing raw DB internals to the user.
void _logError(Object error) {
  if (!kDebugMode) return;
  if (error is PostgrestException) {
    debugPrint(
      'jobzone error → PostgrestException '
      'code=${error.code} message=${error.message} details=${error.details}',
    );
  } else {
    debugPrint('jobzone error → $error');
  }
}
