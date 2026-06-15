import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notifications_repository.dart';
import '../domain/notification.dart';

/// The signed-in user's notifications (newest first), with read mutations.
class NotificationsController extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() =>
      ref.read(notificationsRepositoryProvider).list();

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
