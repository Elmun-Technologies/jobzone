import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../design_system/design_system.dart';
import '../../application/notifications_providers.dart';
import '../../domain/notification.dart';
import '../notification_display.dart';

/// Shows an in-app popup when a notification arrives while the app is open.
///
/// A system push only fires when the app is backgrounded, so without this a
/// new message or job match landed silently: the badge ticked up and nothing
/// else happened. Mounted once from `MaterialApp.builder`, above the Navigator,
/// so it survives every route change and floats over whichever shell tab the
/// user is on.
///
/// The notifications stream (0005 publishes the table to `supabase_realtime`)
/// is already driving [notificationsControllerProvider]; this only diffs its
/// emissions, so there is no second subscription.
class NotificationToastHost extends ConsumerStatefulWidget {
  const NotificationToastHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationToastHost> createState() =>
      _NotificationToastHostState();
}

class _NotificationToastHostState extends ConsumerState<NotificationToastHost> {
  /// Ids already accounted for. The first emission only fills this — otherwise
  /// signing in would fire a toast for every notification ever received.
  final _seen = <String>{};
  bool _primed = false;

  AppNotification? _current;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onData(List<AppNotification> rows) {
    if (!_primed) {
      _seen.addAll(rows.map((n) => n.id));
      _primed = true;
      return;
    }
    // Rows arrive newest-first; the newest unseen unread one wins if several
    // land at once (a burst still leaves the user one thing to tap).
    AppNotification? fresh;
    for (final n in rows) {
      if (_seen.add(n.id) && !n.isRead && fresh == null) fresh = n;
    }
    if (fresh == null || !mounted) return;

    // Don't pop over the screen that already shows the same thing: the
    // notifications list streams live, and a toast for the chat you are
    // reading would fire on every incoming message.
    final path = ref
        .read(goRouterProvider)
        .routerDelegate
        .currentConfiguration
        .uri
        .path;
    if (path == Routes.notifications ||
        path == notificationDestination(fresh)) {
      return;
    }
    setState(() => _current = fresh);
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 5), _dismiss);
  }

  void _dismiss() {
    _timer?.cancel();
    if (mounted) setState(() => _current = null);
  }

  void _open(AppNotification n) {
    final router = ref.read(goRouterProvider);
    _dismiss();
    ref.read(notificationsControllerProvider.notifier).markRead(n.id);
    router.push(notificationDestination(n) ?? Routes.notifications);
  }

  @override
  Widget build(BuildContext context) {
    // A different account starts from a clean slate — otherwise the new user's
    // very first emission would look like a burst of arrivals and toast the
    // whole backlog.
    ref.listen(currentUserIdProvider, (_, _) {
      _seen.clear();
      _primed = false;
      _dismiss();
    });

    ref.listen(notificationsControllerProvider, (_, next) {
      final rows = next.value;
      if (rows != null) _onData(rows);
    });

    final current = _current;
    return Stack(
      // `expand`, not the default loose fit: the non-positioned child here is
      // the app's Navigator, and loose constraints would let it shrink-wrap
      // instead of filling the screen.
      fit: StackFit.expand,
      children: [
        widget.child,
        if (current != null)
          Positioned(
            top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: _ToastCard(
              notification: current,
              onTap: () => _open(current),
              onDismiss: _dismiss,
            ),
          ),
      ],
    );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final body = notificationBody(context, notification);

    final card = Ink(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.chipBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              notificationIcon(notification.type),
              color: colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notificationTitle(context, notification),
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (body != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    // The card lives outside the Navigator, so it has no Material ancestor of
    // its own — text and ink would assert without one. (The status-bar inset
    // is already applied by the Positioned above; no SafeArea here.)
    return Material(
      color: Colors.transparent,
      child: Dismissible(
        key: ValueKey(notification.id),
        direction: DismissDirection.up,
        onDismissed: (_) => onDismiss(),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (t - 1) * 16),
              child: child,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: card,
          ),
        ),
      ),
    );
  }
}
