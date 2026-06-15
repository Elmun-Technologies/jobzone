import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
    final hasUnread = (async.value ?? const []).any((n) => !n.isRead);

    return JzScaffold(
      title: l.notifications,
      actions: [
        if (hasUnread)
          TextButton(
            onPressed: () => ref
                .read(notificationsControllerProvider.notifier)
                .markAllRead(),
            child: Text(l.markAllRead),
          ),
      ],
      body: async.when(
        loading: () => const JzLoader(),
        error: (_, _) => Center(child: Text(l.errUnknown)),
        data: (items) => items.isEmpty
            ? JzEmptyState(
                icon: Icons.notifications_none_rounded,
                title: l.noNotificationsTitle,
                message: l.noNotificationsBody,
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: context.colors.border),
                itemBuilder: (_, i) =>
                    _NotificationTile(notification: items[i]),
              ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});
  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final (icon, tint) = _visuals(notification.type, colors);
    return ListTile(
      onTap: notification.isRead
          ? null
          : () => ref
                .read(notificationsControllerProvider.notifier)
                .markRead(notification.id),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        backgroundColor: tint.withValues(alpha: 0.12),
        child: Icon(icon, color: tint),
      ),
      title: Text(
        notification.title,
        style: context.text.titleSmall?.copyWith(
          fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notification.body != null)
            Text(
              notification.body!,
              style: context.text.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            _relativeTime(notification.createdAt),
            style: context.text.labelSmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
      trailing: notification.isRead
          ? null
          : Container(
              height: 10,
              width: 10,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
            ),
    );
  }

  (IconData, Color) _visuals(NotificationType type, JzColors colors) =>
      switch (type) {
        NotificationType.applicationUpdate => (
          Icons.work_outline_rounded,
          colors.primary,
        ),
        NotificationType.message => (
          Icons.chat_bubble_outline_rounded,
          colors.accent,
        ),
        NotificationType.jobMatch => (
          Icons.auto_awesome_rounded,
          colors.success,
        ),
        NotificationType.review => (Icons.star_outline_rounded, colors.warning),
        NotificationType.system => (
          Icons.info_outline_rounded,
          colors.textSecondary,
        ),
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
