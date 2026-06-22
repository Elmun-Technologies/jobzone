import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/notifications/data/telegram_repository.dart';

void main() {
  // No Supabase env in tests → the repository simulates the link locally.
  test('startLink links offline; unlink clears it', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final repo = c.read(telegramRepositoryProvider);

    expect((await repo.status()).linked, isFalse);

    final token = await repo.startLink();
    expect(token, isNotEmpty);
    expect((await repo.status()).linked, isTrue);

    await repo.unlink();
    expect((await repo.status()).linked, isFalse);
  });
}
