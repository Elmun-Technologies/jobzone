import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/employer/data/wallet_repository.dart';

void main() {
  group('WalletRepository (offline)', () {
    WalletRepository repo() {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      return container.read(walletRepositoryProvider);
    }

    test('a top-up order returns an id and the amount to charge', () async {
      final r = repo();
      final before = (await r.getWallet()).transactions.length;

      final order = await r.createTopUpOrder(75000);

      // The id is what the Payme/Click checkout URL addresses, so it must
      // never come back empty — an empty order id builds a checkout that
      // charges the payer against nothing.
      expect(order.orderId, isNotEmpty);
      expect(order.amountUzs, 75000);

      final wallet = await r.getWallet();
      expect(wallet.transactions.length, before + 1);
      expect(wallet.transactions.first.kind, 'topup');
      // Pending until the gateway callback completes it — a client must never
      // be able to credit itself.
      expect(wallet.transactions.first.isPending, isTrue);
    });

    test('a pending top-up does not move the balance', () async {
      final r = repo();
      final before = (await r.getWallet()).balanceUzs;

      await r.createTopUpOrder(120000);

      expect((await r.getWallet()).balanceUzs, before);
    });

    test('a fractional amount is rounded to whole so\'m', () async {
      final r = repo();

      final order = await r.createTopUpOrder(9999.6);

      // The gateways charge in so'm (Click) / tiyin derived from it (Payme);
      // a fractional so'm would make the two disagree about the amount.
      expect(order.amountUzs, 10000);
    });
  });
}
