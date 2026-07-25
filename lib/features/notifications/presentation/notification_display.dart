import 'package:flutter/material.dart';

import '../../../app/router/routes.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/enums/enums.dart';
import '../../applications/presentation/util/status_label.dart';
import '../domain/notification.dart';

/// How a notification renders and where it leads.
///
/// Shared by the notifications list and the in-app toast — the toast has to
/// show exactly what the list row would show, and route to exactly where
/// tapping the row would go, so keeping one copy is the point of this file.

/// Title in the in-app language (uz/ru/en).
///
/// The server stores a fixed-language string (the triggers in 0005 only ever
/// write one), so titles are re-derived from the type. `review`/`system` are
/// admin/broadcast copy that is already localized upstream, so they pass
/// through unchanged.
String notificationTitle(BuildContext context, AppNotification n) {
  final l = context.l10n;
  return switch (n.type) {
    NotificationType.applicationUpdate => l.notifTitleApplicationUpdate,
    NotificationType.message => l.notifTitleMessage,
    NotificationType.jobMatch => l.notifTitleJobMatch,
    NotificationType.review || NotificationType.system => n.title,
  };
}

/// Body in the in-app language.
///
/// `applicationUpdate`'s stored body is a fixed-language sentence; it is
/// re-derived from `data.status` (always present — see
/// notify_application_status_change()) the same way the title is. Every other
/// type's body is either literal user content (a chat message preview) or
/// already-localized system copy, so it passes through unchanged.
String? notificationBody(BuildContext context, AppNotification n) {
  if (n.type == NotificationType.applicationUpdate) {
    final status = ApplicationStatus.fromWire(n.data['status'] as String?);
    if (status != null) {
      return context.l10n.notifBodyApplicationUpdate(
        applicationStatusLabel(context, status),
      );
    }
  }
  return n.body;
}

IconData notificationIcon(NotificationType type) => switch (type) {
  NotificationType.applicationUpdate => Icons.work_outline_rounded,
  NotificationType.message => Icons.chat_bubble_outline_rounded,
  NotificationType.jobMatch => Icons.work_outline_rounded,
  NotificationType.review => Icons.star_outline_rounded,
  NotificationType.system => Icons.person_outline_rounded,
};

/// Route to push on tap, or null for informational rows with nowhere to go.
/// This completes the alert loop: tapping a job match opens the vacancy.
String? notificationDestination(AppNotification n) {
  String? nav(String key, String Function(String) route) {
    final v = n.data[key];
    return v is String && v.isNotEmpty ? route(v) : null;
  }

  return switch (n.type) {
    NotificationType.jobMatch => nav('job_id', Routes.jobDetails),
    NotificationType.message => nav('conversation_id', Routes.chatDetail),
    NotificationType.applicationUpdate => nav(
      'application_id',
      Routes.applicationStatus,
    ),
    NotificationType.review || NotificationType.system => null,
  };
}
