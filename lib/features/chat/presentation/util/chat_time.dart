import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Compact relative timestamp for the chat list ("now", "12m", "3h", "2d",
/// or a date for older items).
String chatListTime(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return DateFormat.MMMd().format(t);
}

/// Clock time shown under message bubbles (locale-aware).
String messageTime(BuildContext context, DateTime t) =>
    TimeOfDay.fromDateTime(t).format(context);
