/// A company review (`public.company_reviews`). One review per author per
/// company is enforced server-side.
class CompanyReview {
  const CompanyReview({
    this.id,
    required this.companyId,
    required this.rating,
    this.title,
    this.body,
    this.pros,
    this.cons,
    this.isCurrentEmployee = false,
    this.jobTitle,
    this.authorName,
    this.createdAt,
  });

  final String? id;
  final String companyId;
  final int rating;
  final String? title;
  final String? body;
  final String? pros;
  final String? cons;
  final bool isCurrentEmployee;
  final String? jobTitle;
  final String? authorName;
  final DateTime? createdAt;

  factory CompanyReview.fromMap(Map<String, dynamic> m) {
    final author = m['author'];
    return CompanyReview(
      id: m['id'] as String?,
      companyId: (m['company_id'] ?? '') as String,
      rating: (m['rating'] as num?)?.toInt() ?? 0,
      title: m['title'] as String?,
      body: m['body'] as String?,
      pros: m['pros'] as String?,
      cons: m['cons'] as String?,
      isCurrentEmployee: (m['is_current_employee'] ?? false) as bool,
      jobTitle: m['job_title'] as String?,
      authorName: author is Map ? author['full_name'] as String? : null,
      createdAt: DateTime.tryParse('${m['created_at']}'),
    );
  }

  Map<String, dynamic> toInsert(String authorId) => {
    'company_id': companyId,
    'author_id': authorId,
    'rating': rating,
    'title': title,
    'body': body,
    'pros': pros,
    'cons': cons,
    'is_current_employee': isCurrentEmployee,
    'job_title': jobTitle,
  };
}
