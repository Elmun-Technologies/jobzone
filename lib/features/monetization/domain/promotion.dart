/// A purchasable promotion product (mirrors `promotion_products`).
class PromotionProduct {
  const PromotionProduct({
    required this.code,
    required this.name,
    this.description,
    required this.kind, // 'base' | 'top' | 'featured' | 'ai'
    this.priceUzs = 0,
    this.durationDays,
    this.isActive = true,
    this.sortOrder = 0,
  });

  final String code;
  final String name;
  final String? description;
  final String kind;
  final num priceUzs;
  final int? durationDays;
  final bool isActive;
  final int sortOrder;

  bool get isFree => priceUzs <= 0;
  bool get isComingSoon => kind == 'ai';
  bool get isTop => kind == 'top';

  factory PromotionProduct.fromMap(Map<String, dynamic> m) => PromotionProduct(
    code: (m['code'] ?? '') as String,
    name: (m['name'] ?? '') as String,
    description: m['description'] as String?,
    kind: (m['kind'] ?? 'base') as String,
    priceUzs: (m['price_uzs'] as num?) ?? 0,
    durationDays: (m['duration_days'] as num?)?.toInt(),
    isActive: (m['is_active'] ?? true) as bool,
    sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
  );
}

/// A promotion purchase (mirrors `promotion_orders`).
class PromotionOrder {
  const PromotionOrder({
    required this.id,
    this.jobId,
    required this.productCode,
    required this.amountUzs,
    required this.status, // 'pending' | 'paid' | 'cancelled' | 'refunded'
    required this.createdAt,
    this.paidAt,
  });

  final String id;
  final String? jobId;
  final String productCode;
  final num amountUzs;
  final String status;
  final DateTime createdAt;
  final DateTime? paidAt;

  bool get isPaid => status == 'paid';

  factory PromotionOrder.fromMap(Map<String, dynamic> m) => PromotionOrder(
    id: (m['id'] ?? '') as String,
    jobId: m['job_id'] as String?,
    productCode: (m['product_code'] ?? '') as String,
    amountUzs: (m['amount_uzs'] as num?) ?? 0,
    status: (m['status'] ?? 'pending') as String,
    createdAt: DateTime.tryParse('${m['created_at']}') ?? DateTime.now(),
    paidAt: m['paid_at'] != null ? DateTime.tryParse('${m['paid_at']}') : null,
  );
}

/// Formats a UZS amount as "15 000 so'm" (space-grouped thousands).
String formatUzs(num amount) {
  final s = amount.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return "${buf.toString()} so'm";
}
