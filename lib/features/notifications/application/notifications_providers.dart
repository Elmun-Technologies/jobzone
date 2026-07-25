import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/notifications_repository.dart';
import '../domain/notification.dart';

/// The signed-in user's notifications (newest first), with read mutations.
/// Subscribes directly to the repository's realtime stream (0005 publishes
/// `notifications` to `supabase_realtime`) so a new alert or the unread badge
/// updates live, without a manual reopen/reload.
class NotificationsController extends AsyncNotifier<List<AppNotification>> {
  StreamSubscription<List<AppNotification>>? _sub;

  @override
  Future<List<AppNotification>> build() {
    // Rebind when the signed-in identity changes. `stream()` resolves the uid
    // once, at creation — and since the in-app toast host keeps this provider
    // alive app-wide (not just while the notifications page is open), it can
    // now be built *before* sign-in. Without this watch that first, empty
    // subscription would survive the sign-in and never emit anything.
    ref.watch(currentUserIdProvider);

    final repo = ref.read(notificationsRepositoryProvider);
    final completer = Completer<List<AppNotification>>();
    _sub?.cancel();
    _sub = repo.stream().listen(
      (rows) {
        if (!completer.isCompleted) {
          completer.complete(rows);
        } else {
          state = AsyncData(rows);
        }
      },
      onError: (Object e, StackTrace st) {
        if (!completer.isCompleted) {
          completer.completeError(e, st);
        } else {
          state = AsyncError(e, st);
        }
      },
    );
    ref.onDispose(() => _sub?.cancel());
    return completer.future;
  }

  Future<void> markAllRead() async {
    await ref.read(notificationsRepositoryProvider).markAllRead();
    ref.invalidateSelf();
    await future;
  }

  Future<void> markRead(String id) async {
    await ref.read(notificationsRepositoryProvider).markRead(id);
    ref.invalidateSelf();
    await future;
  }
}

final notificationsControllerProvider =
    AsyncNotifierProvider<NotificationsController, List<AppNotification>>(
      NotificationsController.new,
    );

/// Count of unread notifications (drives the app-bar badge). 0 while loading.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final async = ref.watch(notificationsControllerProvider);
  return async.value?.where((n) => !n.isRead).length ?? 0;
});

final notificationSettingsProvider = FutureProvider<NotificationSettings>(
  (ref) => ref.read(notificationsRepositoryProvider).settings(),
);
