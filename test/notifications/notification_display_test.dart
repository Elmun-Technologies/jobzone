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

/// Which titles are the server's own content and which the client localizes.
/// notificationTitle() needs a BuildContext for the localized half, so the
/// decision itself is tested here and the widget just applies it.
void _titleGroup() {
  group('usesStoredTitle', () {
    test('a job match keeps the name the server stored', () {
      // run_saved_search_alerts() (0036) stores the vacancy's own title and
      // invite_candidate() (0050) stores "Ish taklifi". Replacing either with
      // the generic label left the seeker with a company and a city but no
      // idea what the job was.
      expect(usesStoredTitle(NotificationType.jobMatch, 'Payvandchi'), isTrue);
      expect(usesStoredTitle(NotificationType.jobMatch, 'Ish taklifi'), isTrue);
    });

    test('a job match with no title falls back to the generic label', () {
      expect(usesStoredTitle(NotificationType.jobMatch, ''), isFalse);
      expect(usesStoredTitle(NotificationType.jobMatch, '   '), isFalse);
    });

    test('the trigger-written types are always localized', () {
      // 0005 writes the literal English 'Application update' / 'New message'.
      expect(
        usesStoredTitle(
          NotificationType.applicationUpdate,
          'Application update',
        ),
        isFalse,
      );
      expect(usesStoredTitle(NotificationType.message, 'New message'), isFalse);
    });

    test('admin copy is shown exactly as written', () {
      expect(usesStoredTitle(NotificationType.system, 'Texnik ishlar'), isTrue);
      expect(usesStoredTitle(NotificationType.review, 'Yangi sharh'), isTrue);
    });
  });
}

void main() {
  _titleGroup();

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
