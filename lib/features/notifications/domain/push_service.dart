/// Push-notification abstraction (Phase 8 seam).
///
/// Default binding is [NoopPushService] so the app runs without Firebase. To
/// enable remote push, bind `pushServiceProvider` to an FCM implementation and
/// follow `docs/phase-8-realtime-and-push.md`.
library;

/// A received push payload (foreground message or notification tap).
class PushMessage {
  const PushMessage({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;
  final Map<String, dynamic> data;
}

abstract interface class PushService {
  /// Request permission, obtain the device token and register it. Safe to call
  /// after sign-in; a no-op when push isn't configured.
  Future<void> initialize();

  /// The current device push token, if any.
  Future<String?> token();

  /// Foreground push messages.
  Stream<PushMessage> get messages;

  /// Route paths emitted when the user taps a push notification. Listen in the
  /// app root and call `router.push(path)` to land on the right screen.
  Stream<String> get deepLinks;

  /// Persist the device token (e.g. into a `devices` table) for the signed-in
  /// user so the server can target this device.
  Future<void> registerDevice();

  /// Remove this device's token (e.g. on sign-out).
  Future<void> unregister();
}
