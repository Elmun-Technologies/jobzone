import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/noop_push_service.dart';
import '../domain/push_service.dart';

/// **The Phase 8 push seam.** Default = [NoopPushService] (no Firebase).
///
/// To enable FCM, swap to:
/// ```dart
/// final pushServiceProvider =
///     Provider<PushService>((ref) => FcmPushService(ref));
/// ```
/// then call `ref.read(pushServiceProvider).initialize()` after sign-in.
final pushServiceProvider = Provider<PushService>(
  (ref) => const NoopPushService(),
);
