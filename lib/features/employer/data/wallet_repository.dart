import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/wallet.dart';
import 'employer_jobs_repository.dart' show NoCompanyError;

/// The employer's Hamyon (wallet): balance + ledger, and top-up requests.
/// Resolves "my company" internally (mirrors [EmployerJobsRepository]) so
/// callers never pass a company id. Falls back to a small in-memory demo
/// wallet offline, so the promote flow has something real to spend from with
/// no backend configured.
class WalletRepository {
  WalletRepository(this._ref);

  final Ref _ref;

  bool get _live => Env.hasSupabase;

  Future<Map<String, dynamic>?> _ownedCompany() async {
    final client = _ref.read(supabaseClientProvider);
    final uid = client.auth.currentUser?.id;
    if (uid == null) return null;
    return client
        .from('companies')
        .select('id')
        .eq('owner_id', uid)
        .maybeSingle();
  }

  /// The completed-entry balance plus the recent transaction ledger.
  Future<Wallet> getWallet() async {
    if (!_live) return _offlineWallet;
    final company = await _ownedCompany();
    if (company == null) return const Wallet();
    final companyId = company['id'];

    final client = _ref.read(supabaseClientProvider);
    final balanceRow = await client
        .from('wallet_balances')
        .select('balance_uzs')
        .eq('company_id', companyId)
        .maybeSingle();
    final txRows = await client
        .from('wallet_transactions')
        .select()
        .eq('company_id', companyId)
        .order('created_at', ascending: false)
        .limit(50);

    return Wallet(
      balanceUzs: (balanceRow?['balance_uzs'] as num?) ?? 0,
      transactions: (txRows as List)
          .map((r) => WalletTransaction.fromMap(r as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Records a pending top-up request (RLS confines it to the owner). Payments
  /// are record-only until the payment gateway is wired — a webhook later
  /// marks the row `completed`, which moves the balance.
  Future<void> requestTopUp(num amountUzs) async {
    if (!_live) {
      _offlineTransactions.insert(
        0,
        WalletTransaction(
          id: 'tx-${DateTime.now().microsecondsSinceEpoch}',
          kind: 'topup',
          amountUzs: amountUzs,
          status: 'pending',
          createdAt: DateTime.now(),
        ),
      );
      return;
    }
    final company = await _ownedCompany();
    if (company == null) throw const NoCompanyError();
    final client = _ref.read(supabaseClientProvider);
    await client.from('wallet_transactions').insert({
      'company_id': company['id'],
      'kind': 'topup',
      'amount_uzs': amountUzs.round(),
      'status': 'pending',
      'created_by': client.auth.currentUser?.id,
    });
  }

  /// Opens (or re-uses) a pending top-up and returns the id the gateway
  /// checkout addresses, plus the amount the server actually accepted.
  ///
  /// `create_topup_order` (0085) bounds the amount server-side and hands back
  /// the same pending row for a repeated same-amount request — so two payment
  /// attempts settle one row and a single intent can never be credited twice.
  /// The provider's callback flips the row to `completed`, which is what moves
  /// the balance; the client never writes that itself.
  Future<({String orderId, int amountUzs})> createTopUpOrder(
    num amountUzs,
  ) async {
    // Round here too, so the offline substrate records exactly what the RPC
    // would: the gateways charge whole so'm, and a fractional row would make
    // the ledger and the checkout disagree about the amount.
    final rounded = amountUzs.round();
    if (!_live) {
      await requestTopUp(rounded);
      return (
        orderId: 'ord-${DateTime.now().microsecondsSinceEpoch}',
        amountUzs: rounded,
      );
    }
    final client = _ref.read(supabaseClientProvider);
    final data = await client.rpc(
      'create_topup_order',
      params: {'p_amount_uzs': rounded},
    );
    final row = data is List
        ? (data.first as Map<String, dynamic>)
        : (data as Map<String, dynamic>);
    return (
      orderId: row['order_id'].toString(),
      amountUzs: (row['amount_uzs'] as num).toInt(),
    );
  }

  /// Offline-only: applies an immediate completed debit to the demo wallet, so
  /// buying a promotion visibly lowers the balance — matching the effect the
  /// live `buy_promotion` RPC has server-side. No-op live (the RPC itself
  /// writes the debit; the client never spends the wallet directly).
  void debitOffline(num amountUzs, String description) {
    _offlineBalance -= amountUzs;
    _offlineTransactions.insert(
      0,
      WalletTransaction(
        id: 'tx-${DateTime.now().microsecondsSinceEpoch}',
        kind: 'spend',
        amountUzs: -amountUzs,
        status: 'completed',
        description: description,
        createdAt: DateTime.now(),
      ),
    );
  }
}

// Offline demo wallet (process-wide), so the balance persists across reads
// and visibly drops as promotions are purchased.
num _offlineBalance = 500000;
final List<WalletTransaction> _offlineTransactions = [
  WalletTransaction(
    id: 'tx-seed-1',
    kind: 'topup',
    amountUzs: 500000,
    status: 'completed',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
];

Wallet get _offlineWallet => Wallet(
  balanceUzs: _offlineBalance,
  transactions: List.unmodifiable(_offlineTransactions),
);

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(ref),
);

final walletProvider = FutureProvider<Wallet>(
  (ref) => ref.read(walletRepositoryProvider).getWallet(),
);
