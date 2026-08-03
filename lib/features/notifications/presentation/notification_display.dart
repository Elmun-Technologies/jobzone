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

/// Whether the stored title is content that has to survive, or a
/// fixed-language server string the client must replace.
///
/// `applicationUpdate`/`message` come from the 0005 triggers, which write a
/// literal English title — those are re-derived. `review`/`system` carry
/// admin-authored broadcast copy already written in its final language.
///
/// `jobMatch` is the one that matters: `run_saved_search_alerts()` (0036)
/// stores the **vacancy's own name** as the title, and `invite_candidate()`
/// (0050) stores "Ish taklifi". Overwriting both with the generic label left
/// an alert reading "Yangi mos vakansiya / Elmun · Toshkent" — company and
/// city, but not what the job actually is, which is the one fact that decides
/// whether to tap — and turned a direct invitation from an employer into an
/// anonymous algorithmic suggestion.
bool usesStoredTitle(NotificationType type, String title) => switch (type) {
  NotificationType.applicationUpdate || NotificationType.message => false,
  NotificationType.jobMatch => title.trim().isNotEmpty,
  NotificationType.review || NotificationType.system => true,
};

/// Title in the in-app language (uz/ru/en), or the server's own where that is
/// content rather than copy — see [usesStoredTitle].
String notificationTitle(BuildContext context, AppNotification n) {
  // An invitation is an employer addressing this person directly, not the
  // saved-search alert jobMatch otherwise means — and 0050 wrote its heading
  // in Uzbek only, so it is copy, not content, whenever we can rebuild it.
  if (inviteParts(n) != null) return context.l10n.notifTitleJobInvite;
  if (usesStoredTitle(n.type, n.title)) return n.title;
  final l = context.l10n;
  // A vacancy closing is not a decision on the application, so it gets its own
  // heading rather than the generic "your application changed".
  if (isJobClosed(n)) return l.notifTitleJobClosed;
  return switch (n.type) {
    NotificationType.applicationUpdate => l.notifTitleApplicationUpdate,
    NotificationType.message => l.notifTitleMessage,
    // A job match stored without a title of its own. review/system never
    // reach here — usesStoredTitle keeps whatever the admin wrote.
    NotificationType.jobMatch ||
    NotificationType.review ||
    NotificationType.system => l.notifTitleJobMatch,
  };
}

/// Body in the in-app language.
///
/// `applicationUpdate`'s stored body is a fixed-language sentence; it is
/// re-derived from `data.status` (always present — see
/// notify_application_status_change()) the same way the title is. Every other
/// type's body is either literal user content (a chat message preview) or
/// already-localized system copy, so it passes through unchanged.
/// Whether this row is the "the vacancy you applied to was closed" notice
/// raised by 0078, rather than an ordinary status change.
///
/// The trigger stores the vacancy's title as the body and marks the row with
/// `event`, precisely so the sentence around that title can be written in the
/// reader's own language here instead of being fixed in SQL.
bool isJobClosed(AppNotification n) => n.data['event'] == 'job_closed';

/// The company and role an invitation names, when the payload carries them
/// (0079). Null for a saved-search `job_match`, and for invitations written
/// before 0079 — those keep the Uzbek sentence invite_candidate() stored,
/// which is exactly what they show today.
({String company, String title})? inviteParts(AppNotification n) {
  if (n.type != NotificationType.jobMatch || n.data['invited'] != true) {
    return null;
  }
  final company = n.data['company'];
  final title = n.data['title'];
  if (company is! String || company.isEmpty) return null;
  if (title is! String || title.isEmpty) return null;
  return (company: company, title: title);
}

String? notificationBody(BuildContext context, AppNotification n) {
  final invite = inviteParts(n);
  if (invite != null) {
    return context.l10n.notifBodyJobInvite(invite.company, invite.title);
  }
  if (isJobClosed(n)) {
    return context.l10n.notifBodyJobClosed(n.body ?? '');
  }
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
