import '../domain/push_service.dart';

/// Default [PushService]: does nothing. Lets the app build and run without
/// Firebase / FCM configured.
class NoopPushService implements PushService {
  const NoopPushService();

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> token() async => null;

  @override
  Stream<PushMessage> get messages => const Stream.empty();

  @override
  Future<void> registerDevice() async {}

  @override
  Future<void> unregister() async {}
}
