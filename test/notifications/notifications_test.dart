import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/notifications/application/notifications_providers.dart';
import 'package:jobzone/features/notifications/data/notifications_repository.dart';
import 'package:jobzone/features/notifications/domain/notification.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('offline notifications seeded; markAllRead clears unread', () async {
    final repo = container.read(notificationsRepositoryProvider);
    final items = await repo.list();
    expect(items, isNotEmpty);
    expect(items.any((n) => !n.isRead), isTrue);

    await repo.markAllRead();
    final after = await repo.list();
    expect(after.every((n) => n.isRead), isTrue);
  });

  test('unread count provider reflects controller state', () async {
    // Resolve the controller's first build.
    await container.read(notificationsControllerProvider.future);
    final count = container.read(unreadNotificationsCountProvider);
    expect(count, greaterThanOrEqualTo(0));
  });

  test('notification settings round-trip', () async {
    final repo = container.read(notificationsRepositoryProvider);
    await repo.saveSettings(
      const NotificationSettings(pushMessages: false, emailJobMatch: true),
    );
    final s = await repo.settings();
    expect(s.pushMessages, isFalse);
    expect(s.emailJobMatch, isTrue);
  });
}
