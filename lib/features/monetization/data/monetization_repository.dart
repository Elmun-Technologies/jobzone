import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../employer/data/mock_employer.dart';
import '../../employer/data/wallet_repository.dart';
import '../domain/promotion.dart';

/// Thrown when [MonetizationRepository.purchase] can't find [productCode] in
/// the live catalog (a stale client vs. a since-deactivated/renamed product).
class UnknownProductError implements Exception {
  const UnknownProductError(this.code);
  final String code;
  @override
  String toString() => 'UnknownProductError($code)';
}

/// Promotion catalog + per-job purchases, self-serve from the Hamyon wallet.
/// Offline it serves the seeded catalog and, on "purchase", applies the boost
/// to the in-memory job and debits the demo wallet immediately, so the effect
/// is visible without a backend. Live, it calls the `buy_promotion` RPC —
/// security-definer, ownership + balance checked, atomic: debits the wallet,
/// applies the boost, and records a `paid` order server-side in one
/// transaction (the client never writes the boost columns directly).
class MonetizationRepository {
  MonetizationRepository(this._ref);

  final Ref _ref;

  bool get _live => Env.hasSupabase;

  Future<List<PromotionProduct>> products() async {
    if (!_live) return _seed;
    final rows = await _ref
        .read(supabaseClientProvider)
        .from('promotion_products')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return (rows as List)
        .map((e) => PromotionProduct.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PromotionOrder>> myOrders() async {
    if (!_live) return [..._offlineOrders];
    final rows = await _ref
        .read(supabaseClientProvider)
        .from('promotion_orders')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => PromotionOrder.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Buys [productCode] for [jobId] from the employer's Hamyon balance.
  /// Callers should check the wallet balance before calling this (the UI
  /// gates the button on it) — this still enforces it server-side / in the
  /// offline demo, so a race or a stale UI can't overspend.
  Future<PromotionOrder> purchase({
    required String jobId,
    required String productCode,
  }) async {
    final catalog = await products();
    final product = catalog.where((p) => p.code == productCode).firstOrNull;
    if (product == null) throw UnknownProductError(productCode);

    if (!_live) {
      final now = DateTime.now();
      final days = product.durationDays;
      if (days != null &&
          (product.kind == 'top' || product.kind == 'featured')) {
        final jobs = mockEmployer.jobs;
        final i = jobs.indexWhere((j) => j.id == jobId);
        if (i >= 0) {
          jobs[i] = jobs[i].copyWith(
            boostedUntil: now.add(Duration(days: days)),
            boostKind: product.kind,
          );
        }
        _ref
            .read(walletRepositoryProvider)
            .debitOffline(product.priceUzs, 'Koʻtarish: ${product.name}');
      }
      final order = PromotionOrder(
        id: 'ord-${now.microsecondsSinceEpoch}',
        jobId: jobId,
        productCode: productCode,
        amountUzs: product.priceUzs,
        status: 'paid',
        createdAt: now,
        paidAt: now,
      );
      _offlineOrders.insert(0, order);
      return order;
    }

    final client = _ref.read(supabaseClientProvider);
    // The RPC is atomic (debit + boost + paid order, one transaction) and
    // returns the job's new boosted_until — the client doesn't need it since
    // myJobsProvider/myOrdersProvider are invalidated right after to re-fetch
    // the authoritative rows.
    await client.rpc(
      'buy_promotion',
      params: {'p_job_id': jobId, 'p_product_code': productCode},
    );
    final now = DateTime.now();
    return PromotionOrder(
      id: 'live-${now.microsecondsSinceEpoch}',
      jobId: jobId,
      productCode: productCode,
      amountUzs: product.priceUzs,
      status: 'paid',
      createdAt: now,
      paidAt: now,
    );
  }
}

// Offline order store (process-wide), so the Promotions history persists.
final List<PromotionOrder> _offlineOrders = [];

// Offline catalog — mirrors the seed in 0011_monetization.sql.
const _seed = <PromotionProduct>[
  PromotionProduct(
    code: 'start',
    name: 'Start',
    description: 'Standart bepul e\'lon',
    kind: 'base',
    priceUzs: 0,
    sortOrder: 0,
  ),
  PromotionProduct(
    code: 'featured',
    name: 'Tezkor topish',
    description: 'Kategoriyada ajratib ko\'rsatish',
    kind: 'featured',
    priceUzs: 10000,
    durationDays: 7,
    sortOrder: 1,
  ),
  PromotionProduct(
    code: 'top_3',
    name: '3 kun TOP',
    description: 'Ro\'yxat tepasida 3 kun',
    kind: 'top',
    priceUzs: 15000,
    durationDays: 3,
    sortOrder: 2,
  ),
  PromotionProduct(
    code: 'top_7',
    name: '7 kun TOP',
    description: 'Ro\'yxat tepasida 7 kun',
    kind: 'top',
    priceUzs: 35000,
    durationDays: 7,
    sortOrder: 3,
  ),
  PromotionProduct(
    code: 'top_30',
    name: '30 kun TOP',
    description: 'Ro\'yxat tepasida 30 kun',
    kind: 'top',
    priceUzs: 99000,
    durationDays: 30,
    sortOrder: 4,
  ),
  PromotionProduct(
    code: 'ai_screening',
    name: 'AI saralash',
    description: 'Nomzodlarni AI tartiblash (tez orada)',
    kind: 'ai',
    priceUzs: 0,
    sortOrder: 5,
  ),
];

final monetizationRepositoryProvider = Provider<MonetizationRepository>(
  (ref) => MonetizationRepository(ref),
);

final promotionProductsProvider = FutureProvider<List<PromotionProduct>>(
  (ref) => ref.read(monetizationRepositoryProvider).products(),
);

final myOrdersProvider = FutureProvider<List<PromotionOrder>>(
  (ref) => ref.read(monetizationRepositoryProvider).myOrders(),
);
