/// A job posting, flattened with the company display fields (mirrors the
/// `job_feed` view in Postgres and the Meilisearch document).
class Job {
  const Job({
    required this.id,
    required this.title,
    required this.companyId,
    required this.companyName,
    this.companyLogoUrl,
    this.companyVerified = false,
    this.location,
    this.city,
    this.country,
    this.jobType,
    this.experienceLevel,
    this.workingModel,
    this.salaryMin,
    this.salaryMax,
    this.currency,
    this.salaryPeriod,
    this.skills = const [],
    this.description,
    this.responsibilities,
    this.requirements,
    this.benefits,
    this.applicantsCount = 0,
    this.postedAt,
    this.categoryName,
  });

  final String id;
  final String title;
  final String companyId;
  final String companyName;
  final String? companyLogoUrl;
  final bool companyVerified;
  final String? location;
  final String? city;
  final String? country;
  final String? jobType;
  final String? experienceLevel;
  final String? workingModel;
  final num? salaryMin;
  final num? salaryMax;
  final String? currency;
  final String? salaryPeriod;
  final List<String> skills;
  final String? description;
  final String? responsibilities;
  final String? requirements;
  final String? benefits;
  final int applicantsCount;
  final DateTime? postedAt;
  final String? categoryName;

  String get locationText =>
      location ??
      [city, country].where((e) => e != null && e.isNotEmpty).join(', ');

  String get _currencySymbol => switch (currency) {
    'USD' => r'$',
    'EUR' => '€',
    'GBP' => '£',
    _ => (currency == null || currency!.isEmpty) ? '' : '${currency!} ',
  };

  /// e.g. r"$1.5k - $3k". Null when no salary is set.
  String? get salaryText {
    final min = salaryMin;
    final max = salaryMax;
    final s = _currencySymbol;
    String fmt(num v) => v >= 1000
        ? '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}k'
        : v.toStringAsFixed(0);
    if (min != null && max != null) {
      return '$s${fmt(min)} - $s${fmt(max)}';
    }
    final single = min ?? max;
    if (single == null) return null;
    return '$s${fmt(single)}';
  }

  /// e.g. "/month", "/hr". Null when no period is set.
  String? get salaryPeriodSuffix => switch (salaryPeriod) {
    'hour' => '/hr',
    'day' => '/day',
    'week' => '/wk',
    'month' => '/month',
    'year' => '/yr',
    _ => null,
  };

  factory Job.fromMap(Map<String, dynamic> m) {
    num? parseNum(Object? v) =>
        v is num ? v : (v == null ? null : num.tryParse('$v'));
    return Job(
      id: m['id'] as String,
      title: (m['title'] ?? '') as String,
      companyId: (m['company_id'] ?? '') as String,
      companyName: (m['company_name'] ?? '') as String,
      companyLogoUrl: m['company_logo_url'] as String?,
      companyVerified: (m['company_is_verified'] ?? false) as bool,
      location: m['location'] as String?,
      city: m['city'] as String?,
      country: m['country'] as String?,
      jobType: m['job_type'] as String?,
      experienceLevel: m['experience_level'] as String?,
      workingModel: m['working_model'] as String?,
      salaryMin: parseNum(m['salary_min']),
      salaryMax: parseNum(m['salary_max']),
      currency: m['currency'] as String?,
      salaryPeriod: m['salary_period'] as String?,
      skills:
          (m['skills_required'] as List?)?.map((e) => '$e').toList() ??
          const [],
      description: m['description'] as String?,
      responsibilities: m['responsibilities'] as String?,
      requirements: m['requirements'] as String?,
      benefits: m['benefits'] as String?,
      applicantsCount: (m['applicants_count'] ?? 0) as int,
      postedAt: m['posted_at'] != null
          ? DateTime.tryParse('${m['posted_at']}')
          : null,
      categoryName: m['category_name'] as String?,
    );
  }
}
