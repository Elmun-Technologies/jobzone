import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notifications_repository.dart';
import '../domain/notification.dart';

/// Realtime notifications stream (0005 publishes `notifications` to
/// `supabase_realtime`) — the source [NotificationsController] rebuilds from
/// whenever a row is inserted/updated, so new alerts and the unread badge
/// stay live without a manual reopen/reload.
final _notificationsStreamProvider = StreamProvider<List<AppNotification>>(
  (ref) => ref.read(notificationsRepositoryProvider).stream(),
);

/// The signed-in user's notifications (newest first), with read mutations.
class NotificationsController extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() =>
      ref.watch(_notificationsStreamProvider.future);

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
