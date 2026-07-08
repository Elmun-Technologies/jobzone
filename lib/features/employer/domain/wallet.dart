/// A single Hamyon (wallet) ledger entry (mirrors `wallet_transactions`).
class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.kind, // 'topup' | 'spend' | 'refund' | 'bonus'
    required this.amountUzs, // signed: positive = credit, negative = debit
    required this.status, // 'pending' | 'completed' | 'cancelled'
    this.description,
    required this.createdAt,
  });

  final String id;
  final String kind;
  final num amountUzs;
  final String status;
  final String? description;
  final DateTime createdAt;

  bool get isCredit => amountUzs >= 0;
  bool get isPending => status == 'pending';

  factory WalletTransaction.fromMap(Map<String, dynamic> m) =>
      WalletTransaction(
        id: (m['id'] ?? '') as String,
        kind: (m['kind'] ?? 'topup') as String,
        amountUzs: (m['amount_uzs'] as num?) ?? 0,
        status: (m['status'] ?? 'pending') as String,
        description: m['description'] as String?,
        createdAt: DateTime.tryParse('${m['created_at']}') ?? DateTime.now(),
      );
}

/// The employer's Hamyon: completed-entry balance + recent ledger.
class Wallet {
  const Wallet({this.balanceUzs = 0, this.transactions = const []});

  final num balanceUzs;
  final List<WalletTransaction> transactions;
}
