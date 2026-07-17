import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/routes.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/enums/enums.dart';
import '../../../shared/providers/app_flags.dart';
import '../domain/push_service.dart';

/// Channel id referenced by `com.google.firebase.messaging.default_notification_channel_id`
/// in AndroidManifest.xml. Both must stay in sync — the manifest meta-data
/// tells Firebase which channel to route notification-only payloads into, and
/// the channel MUST exist on the device before the first push or Android
/// silently drops the notification.
const String _fcmChannelId = 'default_high_importance';

/// FCM implementation of [PushService] (Phase 8).
///
/// Bound by `pushServiceProvider` only when Firebase initialized successfully
/// (`firebaseReady`), so its `firebase_messaging` calls never run without native
/// config. To go live the host app must add the Firebase project files — see
/// `docs/phase-8-realtime-and-push.md`. The server side (devices table +
/// push-dispatch / notify-dispatch fan-out) is already in place.
class FcmPushService implements PushService {
  FcmPushService(this._ref);

  final Ref _ref;
  String? _token;
  final _controller = StreamController<PushMessage>.broadcast();
  final _deepLinkController = StreamController<String>.broadcast();

  @override
  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    await _ensureAndroidChannel();
    // Show foreground notifications on iOS (Android shows via the system tray /
    // an in-app listener on [messages]).
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    _token = await messaging.getToken();

    // Foreground messages — surface via the [messages] stream.
    FirebaseMessaging.onMessage.listen(
      (m) => _controller.add(
        PushMessage(
          title: m.notification?.title,
          body: m.notification?.body,
          data: m.data,
        ),
      ),
    );

    // Background tap: app was already running, user tapped the notification.
    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      final path = _routeFor(m.data);
      if (path != null) _deepLinkController.add(path);
    });

    // Cold start: app was killed, tapping the notification opened it.
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      final path = _routeFor(initial.data);
      if (path != null) _deepLinkController.add(path);
    }

    messaging.onTokenRefresh.listen((t) {
      _token = t;
      registerDevice();
    });
    await registerDevice();
  }

  /// Registers the high-importance Android notification channel that the
  /// manifest's `default_notification_channel_id` meta-data points at.
  /// Idempotent — Android quietly merges duplicate `createNotificationChannel`
  /// calls. iOS handles channels differently (via UNNotificationCategory,
  /// which we skip) so this is a no-op there.
  Future<void> _ensureAndroidChannel() async {
    if (kIsWeb || !Platform.isAndroid) return;
    const channel = AndroidNotificationChannel(
      _fcmChannelId,
      'Yollla notifications',
      description:
          'Job matches, application updates, and messages from employers.',
      importance: Importance.high,
    );
    final plugin = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await plugin?.createNotificationChannel(channel);
  }

  /// Maps a notification data payload to a go_router path, or null when the
  /// notification has no associated screen (e.g. generic system alerts).
  String? _routeFor(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'message':
        final cid = data['conversation_id'] as String?;
        return cid != null ? Routes.chatDetail(cid) : null;
      case 'application_update':
        final aid = data['application_id'] as String?;
        if (aid == null) return null;
        final isEmployer =
            _ref.read(appFlagsProvider).role == UserRole.employer;
        return isEmployer
            ? Routes.employerApplicant(aid)
            : Routes.applicationStatus(aid);
      default:
        return null;
    }
  }

  @override
  Future<String?> token() async => _token;

  @override
  Stream<PushMessage> get messages => _controller.stream;

  @override
  Stream<String> get deepLinks => _deepLinkController.stream;

  @override
  Future<void> registerDevice() async {
    final token = _token;
    if (token == null) return;
    final client = _ref.read(supabaseClientProvider);
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    // Upsert into the devices table (see migration 0008).
    await client.from('devices').upsert({
      'profile_id': uid,
      'fcm_token': token,
      'platform': 'mobile',
    }, onConflict: 'fcm_token');
  }

  @override
  Future<void> unregister() async {
    final token = _token;
    if (token == null) return;
    await _ref
        .read(supabaseClientProvider)
        .from('devices')
        .delete()
        .eq('fcm_token', token);
  }
}
