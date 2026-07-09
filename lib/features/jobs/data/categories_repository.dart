import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';

/// A job category (mirrors a `job_categories` row).
class JobCategory {
  const JobCategory({required this.id, required this.name, required this.slug});

  final String id;
  final String name;
  final String slug;

  /// Emoji icon derived from the category slug; used in browse-by-category UI.
  String get emoji => _emojis[slug] ?? '🗂️';

  static const _emojis = <String, String>{
    'engineering': '💻',
    'design': '🎨',
    'product': '📋',
    'marketing': '📢',
    'sales': '🛒',
    'finance': '💰',
    'hr': '👥',
    'support': '💬',
    'data-ai': '🤖',
    'operations': '⚙️',
    'horeca': '🍽️',
    'retail': '🛍️',
    'logistics-delivery': '🚚',
    'construction': '🏗️',
    'driver': '🚗',
    'warehouse': '📦',
    'security': '🛡️',
    'cleaning': '🧹',
    'beauty': '✂️',
    'manufacturing': '🏭',
    'agriculture': '🌾',
    'foreign-jobs': '✈️',
  };

  factory JobCategory.fromMap(Map<String, dynamic> m) => JobCategory(
    id: (m['id'] ?? '') as String,
    name: (m['name'] ?? '') as String,
    slug: (m['slug'] ?? '') as String,
  );
}

/// Reads the job-category taxonomy. Live: the `job_categories` table. Offline:
/// a static list mirroring `seed.sql` (+ the blue-collar additions). Offline
/// ids are the slugs, so a category chosen in a form still round-trips.
class CategoriesRepository {
  CategoriesRepository(this._ref);

  final Ref _ref;

  bool get _live => Env.hasSupabase;

  Future<List<JobCategory>> categories() async {
    if (!_live) return seed;
    final rows = await _ref
        .read(supabaseClientProvider)
        .from('job_categories')
        .select('id, name, slug')
        .eq('is_active', true)
        .order('sort_order')
        .order('name');
    return (rows as List)
        .map((r) => JobCategory.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// The offline category by id (== slug); used to resolve a display name when
  /// creating a job in the in-memory store.
  static JobCategory? byId(String? id) {
    if (id == null) return null;
    for (final c in seed) {
      if (c.id == id) return c;
    }
    return null;
  }

  static const seed = <JobCategory>[
    JobCategory(id: 'engineering', name: 'Engineering', slug: 'engineering'),
    JobCategory(id: 'design', name: 'Design', slug: 'design'),
    JobCategory(id: 'product', name: 'Product', slug: 'product'),
    JobCategory(id: 'marketing', name: 'Marketing', slug: 'marketing'),
    JobCategory(id: 'sales', name: 'Sales', slug: 'sales'),
    JobCategory(id: 'finance', name: 'Finance', slug: 'finance'),
    JobCategory(id: 'hr', name: 'Human Resources', slug: 'hr'),
    JobCategory(id: 'support', name: 'Customer Support', slug: 'support'),
    JobCategory(id: 'data-ai', name: 'Data & AI', slug: 'data-ai'),
    JobCategory(id: 'operations', name: 'Operations', slug: 'operations'),
    // Blue-collar / mass-hiring + foreign jobs.
    JobCategory(
      id: 'horeca',
      name: 'Restaurants & Hospitality',
      slug: 'horeca',
    ),
    JobCategory(id: 'retail', name: 'Retail & Sales', slug: 'retail'),
    JobCategory(
      id: 'logistics-delivery',
      name: 'Logistics & Delivery',
      slug: 'logistics-delivery',
    ),
    JobCategory(id: 'construction', name: 'Construction', slug: 'construction'),
    JobCategory(id: 'driver', name: 'Drivers', slug: 'driver'),
    JobCategory(id: 'warehouse', name: 'Warehouse', slug: 'warehouse'),
    JobCategory(id: 'security', name: 'Security', slug: 'security'),
    JobCategory(id: 'cleaning', name: 'Cleaning', slug: 'cleaning'),
    JobCategory(id: 'beauty', name: 'Beauty & Salon', slug: 'beauty'),
    JobCategory(
      id: 'manufacturing',
      name: 'Manufacturing',
      slug: 'manufacturing',
    ),
    JobCategory(id: 'agriculture', name: 'Agriculture', slug: 'agriculture'),
    JobCategory(id: 'foreign-jobs', name: 'Foreign Jobs', slug: 'foreign-jobs'),
  ];
}

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => CategoriesRepository(ref),
);

/// The job-category taxonomy for selectors and filters.
final jobCategoriesProvider = FutureProvider<List<JobCategory>>(
  (ref) => ref.read(categoriesRepositoryProvider).categories(),
);
