import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fcm_push_service.dart';
import '../data/noop_push_service.dart';
import '../domain/push_service.dart';

/// Set to true by `bootstrap()` once `Firebase.initializeApp()` succeeds. When
/// false — on web, in dev, or whenever no native Firebase config is present —
/// the app uses [NoopPushService] and push is silently disabled.
bool firebaseReady = false;

/// **The push seam.** Resolves to [FcmPushService] once Firebase is ready, else
/// [NoopPushService]. Call `initialize()` after sign-in and `unregister()`
/// before sign-out.
final pushServiceProvider = Provider<PushService>(
  (ref) => firebaseReady ? FcmPushService(ref) : const NoopPushService(),
);
