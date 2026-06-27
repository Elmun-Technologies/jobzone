import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/notifications/application/push_providers.dart';
import 'package:jobzone/features/notifications/data/noop_push_service.dart';

void main() {
  test('NoopPushService is inert and safe to call', () async {
    const service = NoopPushService();

    // None of these should throw or block.
    await service.initialize();
    await service.registerDevice();
    await service.unregister();
    expect(await service.token(), isNull);
    expect(await service.messages.isEmpty, isTrue);
  });

  test('pushServiceProvider falls back to Noop when Firebase is off', () {
    // No bootstrap() in tests → firebaseReady stays false → no firebase_messaging.
    expect(firebaseReady, isFalse);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(pushServiceProvider), isA<NoopPushService>());
  });
}
