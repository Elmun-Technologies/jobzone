import '../../../shared/enums/enums.dart';

/// An in-app notification (`public.notifications`).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.isRead = false,
    required this.createdAt,
    this.data = const {},
  });

  final String id;
  final NotificationType type;
  final String title;
  final String? body;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
    data: data,
  );

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
    id: (m['id'] ?? '') as String,
    type:
        NotificationType.fromWire(m['type'] as String?) ??
        NotificationType.system,
    title: (m['title'] ?? '') as String,
    body: m['body'] as String?,
    isRead: (m['is_read'] ?? false) as bool,
    createdAt:
        DateTime.tryParse('${m['created_at']}')?.toLocal() ?? DateTime.now(),
    data: (m['data'] as Map?)?.cast<String, dynamic>() ?? const {},
  );
}

/// Per-channel notification preferences (`public.notification_settings`).
class NotificationSettings {
  const NotificationSettings({
    this.pushMessages = true,
    this.pushApplication = true,
    this.pushJobMatch = true,
    this.pushReviews = true,
    this.emailMessages = false,
    this.emailApplication = true,
    this.emailJobMatch = false,
  });

  final bool pushMessages;
  final bool pushApplication;
  final bool pushJobMatch;
  final bool pushReviews;
  final bool emailMessages;
  final bool emailApplication;
  final bool emailJobMatch;

  NotificationSettings copyWith({
    bool? pushMessages,
    bool? pushApplication,
    bool? pushJobMatch,
    bool? pushReviews,
    bool? emailMessages,
    bool? emailApplication,
    bool? emailJobMatch,
  }) => NotificationSettings(
    pushMessages: pushMessages ?? this.pushMessages,
    pushApplication: pushApplication ?? this.pushApplication,
    pushJobMatch: pushJobMatch ?? this.pushJobMatch,
    pushReviews: pushReviews ?? this.pushReviews,
    emailMessages: emailMessages ?? this.emailMessages,
    emailApplication: emailApplication ?? this.emailApplication,
    emailJobMatch: emailJobMatch ?? this.emailJobMatch,
  );

  factory NotificationSettings.fromMap(Map<String, dynamic> m) =>
      NotificationSettings(
        pushMessages: (m['push_messages'] ?? true) as bool,
        pushApplication: (m['push_application'] ?? true) as bool,
        pushJobMatch: (m['push_job_match'] ?? true) as bool,
        pushReviews: (m['push_reviews'] ?? true) as bool,
        emailMessages: (m['email_messages'] ?? false) as bool,
        emailApplication: (m['email_application'] ?? true) as bool,
        emailJobMatch: (m['email_job_match'] ?? false) as bool,
      );

  Map<String, dynamic> toMap() => {
    'push_messages': pushMessages,
    'push_application': pushApplication,
    'push_job_match': pushJobMatch,
    'push_reviews': pushReviews,
    'email_messages': emailMessages,
    'email_application': emailApplication,
    'email_job_match': emailJobMatch,
  };
}
