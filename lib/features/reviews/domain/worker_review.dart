/// An employer's review of a worker (`public.worker_reviews`). One per
/// (worker, author, job) is enforced server-side.
class WorkerReview {
  const WorkerReview({
    this.id,
    required this.workerId,
    required this.rating,
    this.reliability,
    this.body,
    this.jobId,
    this.authorName,
    this.createdAt,
  });

  final String? id;
  final String workerId;
  final int rating;
  final int? reliability;
  final String? body;
  final String? jobId;
  final String? authorName;
  final DateTime? createdAt;

  factory WorkerReview.fromMap(Map<String, dynamic> m) {
    final author = m['author'];
    return WorkerReview(
      id: m['id'] as String?,
      workerId: (m['worker_id'] ?? '') as String,
      rating: (m['rating'] as num?)?.toInt() ?? 0,
      reliability: (m['reliability'] as num?)?.toInt(),
      body: m['body'] as String?,
      jobId: m['job_id'] as String?,
      authorName: author is Map ? author['full_name'] as String? : null,
      createdAt: DateTime.tryParse('${m['created_at']}'),
    );
  }

  Map<String, dynamic> toInsert(String authorId) => {
    'worker_id': workerId,
    'author_id': authorId,
    'rating': rating,
    if (reliability != null) 'reliability': reliability,
    'body': body,
    'job_id': jobId,
  };
}

/// Aggregated worker reputation (`worker_reliability_summary`).
class WorkerReputation {
  const WorkerReputation({
    this.avgRating = 0,
    this.avgReliability = 0,
    this.reviewCount = 0,
    this.reliabilityScore = 0,
  });

  final double avgRating;
  final double avgReliability;
  final int reviewCount;
  final int reliabilityScore;

  bool get hasReviews => reviewCount > 0;

  factory WorkerReputation.fromMap(Map<String, dynamic> m) => WorkerReputation(
    avgRating: (m['avg_rating'] as num?)?.toDouble() ?? 0,
    avgReliability: (m['avg_reliability'] as num?)?.toDouble() ?? 0,
    reviewCount: (m['review_count'] as num?)?.toInt() ?? 0,
    reliabilityScore: (m['reliability_score'] as num?)?.toInt() ?? 0,
  );
}
