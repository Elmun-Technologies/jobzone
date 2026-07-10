import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/enums/enums.dart';
import '../domain/notification.dart';

/// Reads notifications + per-channel settings. Offline mode keeps an in-memory
/// list (and settings) so the screens are demoable without a backend.
class NotificationsRepository {
  NotificationsRepository(this._ref);

  final Ref _ref;

  bool get _online => Env.hasSupabase;
  String? get _uid => _ref.read(supabaseClientProvider).auth.currentUser?.id;

  Future<List<AppNotification>> list() async {
    if (!_online) return List.unmodifiable(_offline.items);
    final uid = _uid;
    if (uid == null) return const [];
    final rows = await _ref
        .read(supabaseClientProvider)
        .from('notifications')
        .select()
        .eq('recipient_id', uid)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => AppNotification.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAllRead() async {
    if (!_online) {
      _offline.markAllRead();
      return;
    }
    final uid = _uid;
    if (uid == null) return;
    await _ref
        .read(supabaseClientProvider)
        .from('notifications')
        .update({'is_read': true})
        .eq('recipient_id', uid)
        .eq('is_read', false);
  }

  Future<void> markRead(String id) async {
    if (!_online) {
      _offline.markRead(id);
      return;
    }
    await _ref
        .read(supabaseClientProvider)
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
  }

  Future<NotificationSettings> settings() async {
    if (!_online) return _offline.settings;
    final uid = _uid;
    if (uid == null) return const NotificationSettings();
    final row = await _ref
        .read(supabaseClientProvider)
        .from('notification_settings')
        .select()
        .eq('profile_id', uid)
        .maybeSingle();
    return row == null
        ? const NotificationSettings()
        : NotificationSettings.fromMap(row);
  }

  Future<void> saveSettings(NotificationSettings s) async {
    if (!_online) {
      _offline.settings = s;
      return;
    }
    final uid = _uid;
    if (uid == null) return;
    await _ref
        .read(supabaseClientProvider)
        .from('notification_settings')
        .upsert({'profile_id': uid, ...s.toMap()});
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref),
);

// --- Offline sample data -----------------------------------------------------
class _OfflineNotifications {
  NotificationSettings settings = const NotificationSettings();

  final items = <AppNotification>[
    AppNotification(
      id: 'n1',
      type: NotificationType.applicationUpdate,
      title: 'Ariza holati yangilandi',
      body: 'Oshpaz lavozimiga arizangiz "Suhbatga taklif" bosqichiga oʻtdi.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AppNotification(
      id: 'n2',
      type: NotificationType.message,
      title: 'Yangi xabar',
      body: 'Dilnoza: Suhbatlashishni intiqlik bilan kutyapman!',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'n3',
      type: NotificationType.jobMatch,
      title: 'Yangi mos vakansiya',
      body:
          '"Yaxshi Savdo" doʻkonidagi "Sotuvchi" vakansiyasi afzalliklaringizga mos keldi.',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  void markAllRead() {
    for (var i = 0; i < items.length; i++) {
      items[i] = items[i].copyWith(isRead: true);
    }
  }

  void markRead(String id) {
    final i = items.indexWhere((n) => n.id == id);
    if (i != -1) items[i] = items[i].copyWith(isRead: true);
  }
}

final _offline = _OfflineNotifications();
