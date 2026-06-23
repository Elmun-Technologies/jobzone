import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/push_service.dart';

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

  @override
  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    // Show foreground notifications on iOS (Android shows via the system tray /
    // an in-app listener on [messages]).
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    _token = await messaging.getToken();
    FirebaseMessaging.onMessage.listen(
      (m) => _controller.add(
        PushMessage(
          title: m.notification?.title,
          body: m.notification?.body,
          data: m.data,
        ),
      ),
    );
    messaging.onTokenRefresh.listen((t) {
      _token = t;
      registerDevice();
    });
    await registerDevice();
  }

  @override
  Future<String?> token() async => _token;

  @override
  Stream<PushMessage> get messages => _controller.stream;

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
