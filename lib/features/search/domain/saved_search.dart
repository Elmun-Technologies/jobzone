/// A stored job search the seeker can re-run ("Obunalar"). Notifying on new
/// matches is a later follow-up.
class SavedSearch {
  const SavedSearch({
    required this.id,
    required this.name,
    this.keywords,
    this.city,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? keywords;
  final String? city;
  final DateTime? createdAt;

  factory SavedSearch.fromMap(Map<String, dynamic> m) {
    final created = m['created_at'];
    return SavedSearch(
      id: m['id'] as String,
      name: (m['name'] ?? '') as String,
      keywords: m['keywords'] as String?,
      city: m['city'] as String?,
      createdAt: created is String ? DateTime.tryParse(created) : null,
    );
  }
}
