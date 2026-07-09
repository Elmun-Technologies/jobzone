import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/enums/enums.dart';
import '../application/notifications_providers.dart';
import '../domain/notification.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(notificationsControllerProvider);
    final unread = (async.value ?? const []).where((n) => !n.isRead).length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(
                title: l.notifications,
                actions: [if (unread > 0) _NewBadge(count: unread)],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const TileListSkeleton(),
                error: (_, _) => JzErrorState(
                  title: l.errorTitle,
                  message: l.errUnknown,
                  retryLabel: l.retry,
                  onRetry: () =>
                      ref.invalidate(notificationsControllerProvider),
                ),
                data: (items) => items.isEmpty
                    ? JzEmptyState(
                        icon: Icons.notifications_none_rounded,
                        title: l.noNotificationsTitle,
                        message: l.noNotificationsBody,
                      )
                    : _GroupedList(items: items),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$count ${context.l10n.newLabel}',
        style: context.text.labelMedium?.copyWith(
          color: colors.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GroupedList extends ConsumerWidget {
  const _GroupedList({required this.items});
  final List<AppNotification> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<AppNotification>>{};
    for (final n in items) {
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      final key = d == today
          ? l.today
          : (d == yesterday ? l.yesterday : l.earlier);
      (groups[key] ??= []).add(n);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        for (final (i, entry) in groups.entries.indexed) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    entry.key.toUpperCase(),
                    style: context.text.labelMedium?.copyWith(
                      color: context.colors.textSecondary,
                      letterSpacing: 1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Only once (first group) — it acts on all notifications, so
                // repeating it per date-group was misleading and overflowed.
                if (i == 0)
                  GestureDetector(
                    onTap: () => ref
                        .read(notificationsControllerProvider.notifier)
                        .markAllRead(),
                    child: Text(
                      l.markAllRead,
                      style: context.text.labelMedium?.copyWith(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (final n in entry.value) _NotificationTile(notification: n),
        ],
      ],
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});
  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final unread = !notification.isRead;
    return InkWell(
      onTap: () => _open(context, ref),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: colors.chipBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _icon(notification.type),
                color: colors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: unread
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _relativeTime(notification.createdAt),
                        style: context.text.labelSmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (notification.body != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      notification.body!,
                      style: context.text.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mark read on tap, then deep-link by type — this completes the alert loop:
  // tapping a job-match notification opens the matching vacancy.
  void _open(BuildContext context, WidgetRef ref) {
    if (!notification.isRead) {
      ref
          .read(notificationsControllerProvider.notifier)
          .markRead(notification.id);
    }
    final dest = _destination();
    if (dest != null) context.push(dest);
  }

  String? _destination() {
    final data = notification.data;
    String? nav(String key, String Function(String) route) {
      final v = data[key];
      return v is String && v.isNotEmpty ? route(v) : null;
    }

    return switch (notification.type) {
      NotificationType.jobMatch => nav('job_id', Routes.jobDetails),
      NotificationType.message => nav('conversation_id', Routes.chatDetail),
      NotificationType.applicationUpdate => nav(
        'application_id',
        Routes.applicationStatus,
      ),
      NotificationType.review || NotificationType.system => null,
    };
  }

  IconData _icon(NotificationType type) => switch (type) {
    NotificationType.applicationUpdate => Icons.work_outline_rounded,
    NotificationType.message => Icons.chat_bubble_outline_rounded,
    NotificationType.jobMatch => Icons.work_outline_rounded,
    NotificationType.review => Icons.star_outline_rounded,
    NotificationType.system => Icons.person_outline_rounded,
  };

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat.MMMd().format(t);
  }
}
