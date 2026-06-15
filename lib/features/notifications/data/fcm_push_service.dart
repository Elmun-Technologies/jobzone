import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/push_service.dart';

/// FCM implementation **template** (Phase 8).
///
/// This file does NOT import `firebase_messaging` / `firebase_core` so the
/// project builds without those dependencies. To go live:
///
/// 1. `flutter pub add firebase_core firebase_messaging` and run flutterfire
///    configure (adds platform Firebase config).
/// 2. `await Firebase.initializeApp()` in `bootstrap()`.
/// 3. Uncomment the `// FCM:` calls below.
/// 4. Bind `pushServiceProvider` to `FcmPushService.new` and call
///    `ref.read(pushServiceProvider).initialize()` after sign-in.
/// 5. Apply migration `0008_devices_push.sql` (the `devices` table) and deploy
///    the `push-dispatch` Edge Function.
class FcmPushService implements PushService {
  FcmPushService(this._ref);

  final Ref _ref;
  String? _token;

  @override
  Future<void> initialize() async {
    // FCM:
    // final messaging = FirebaseMessaging.instance;
    // await messaging.requestPermission();
    // _token = await messaging.getToken();
    // FirebaseMessaging.onMessage.listen((m) => _controller.add(PushMessage(
    //   title: m.notification?.title,
    //   body: m.notification?.body,
    //   data: m.data,
    // )));
    // messaging.onTokenRefresh.listen((t) { _token = t; registerDevice(); });
    await registerDevice();
  }

  @override
  Future<String?> token() async => _token;

  @override
  Stream<PushMessage> get messages => const Stream.empty();

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
