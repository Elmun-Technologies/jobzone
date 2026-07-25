import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/notifications/domain/notification.dart';
import 'package:jobzone/features/notifications/presentation/notification_display.dart';
import 'package:jobzone/shared/enums/enums.dart';

AppNotification _n(NotificationType type, Map<String, dynamic> data) =>
    AppNotification(
      id: 'n1',
      type: type,
      title: 't',
      createdAt: DateTime(2026, 1, 1),
      data: data,
    );

void main() {
  // The list rows and the in-app toast both route through this, so a
  // regression here breaks two entry points at once.
  group('notificationDestination', () {
    test('job match deep-links to the vacancy', () {
      expect(
        notificationDestination(
          _n(NotificationType.jobMatch, {'job_id': 'j1'}),
        ),
        '/jobs/j1',
      );
    });

    test('message deep-links to the conversation', () {
      expect(
        notificationDestination(
          _n(NotificationType.message, {'conversation_id': 'c1'}),
        ),
        '/chat/c1',
      );
    });

    test('application update deep-links to the application', () {
      expect(
        notificationDestination(
          _n(NotificationType.applicationUpdate, {'application_id': 'a1'}),
        ),
        '/account/my-applications/a1',
      );
    });

    test('informational types have nowhere to go', () {
      expect(notificationDestination(_n(NotificationType.system, {})), isNull);
      expect(notificationDestination(_n(NotificationType.review, {})), isNull);
    });

    test('a malformed payload never yields a broken path', () {
      // Must not produce "/jobs/null" or "/jobs/42".
      expect(
        notificationDestination(_n(NotificationType.jobMatch, {})),
        isNull,
      );
      expect(
        notificationDestination(_n(NotificationType.jobMatch, {'job_id': 42})),
        isNull,
      );
      expect(
        notificationDestination(_n(NotificationType.jobMatch, {'job_id': ''})),
        isNull,
      );
    });
  });

  group('notificationIcon', () {
    test('every type maps to an icon', () {
      for (final type in NotificationType.values) {
        expect(notificationIcon(type), isNotNull);
      }
    });
  });
}
