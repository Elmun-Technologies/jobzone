import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../employer/data/mock_employer.dart';
import '../domain/promotion.dart';

/// Promotion catalog + per-job purchases. Offline it serves the seeded catalog
/// and, on "purchase", applies the boost to the in-memory job immediately so
/// the effect is visible without a backend. Live, it creates a `pending` order
/// (a backend admin / payment webhook flips it to `paid`, which applies the
/// boost via the DB trigger — the client never boosts a job directly).
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

  /// Buys [productCode] for [jobId]. Offline applies the boost and returns a
  /// paid order; live inserts a pending order.
  Future<PromotionOrder> purchase({
    required String jobId,
    required String productCode,
  }) async {
    final product = (await products()).firstWhere((p) => p.code == productCode);

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
    final uid = client.auth.currentUser?.id;
    final company = await client
        .from('companies')
        .select('id')
        .eq('owner_id', uid as Object)
        .maybeSingle();
    final row = await client
        .from('promotion_orders')
        .insert({
          'company_id': company?['id'],
          'job_id': jobId,
          'product_code': productCode,
          'amount_uzs': product.priceUzs,
          'created_by': uid,
          'status': 'pending',
        })
        .select()
        .single();
    return PromotionOrder.fromMap(row);
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
