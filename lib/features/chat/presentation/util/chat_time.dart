import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../localization/l10n_extension.dart';

/// Compact localized relative timestamp for the chat list ("hozir", "12 daq",
/// "3 soat", "2 kun", or a date for older items).
String chatListTime(BuildContext context, DateTime t) {
  final l = context.l10n;
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return l.relNow;
  if (diff.inMinutes < 60) return l.relMinutes(diff.inMinutes);
  if (diff.inHours < 24) return l.relHours(diff.inHours);
  if (diff.inDays < 7) return l.relDays(diff.inDays);
  return DateFormat.MMMd().format(t);
}

/// Clock time shown under message bubbles (locale-aware).
String messageTime(BuildContext context, DateTime t) =>
    TimeOfDay.fromDateTime(t).format(context);
