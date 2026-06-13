import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/auth/application/auth_controller.dart';
import 'package:jobzone/features/auth/data/auth_repository_impl.dart';
import 'package:jobzone/features/auth/domain/auth_failure.dart';
import 'package:jobzone/features/auth/domain/auth_repository.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.error});

  final Object? error;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (error != null) throw error!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  test('signIn success → data state, returns true', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      ],
    );
    addTearDown(container.dispose);

    final ok = await container
        .read(authControllerProvider.notifier)
        .signIn(email: 'a@b.com', password: 'secret123');

    expect(ok, isTrue);
    expect(container.read(authControllerProvider).hasError, isFalse);
  });

  test(
    'signIn failure → error is a normalized AuthFailure, returns false',
    () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FakeAuthRepository(error: const InvalidCredentialsFailure()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final ok = await container
          .read(authControllerProvider.notifier)
          .signIn(email: 'a@b.com', password: 'wrong');

      expect(ok, isFalse);
      final state = container.read(authControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<InvalidCredentialsFailure>());
    },
  );
}
