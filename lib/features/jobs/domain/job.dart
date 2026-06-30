import 'job_language.dart';
import 'screening_question.dart';

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
    this.addressText,
    this.city,
    this.country,
    this.region,
    this.district,
    this.lat,
    this.lng,
    this.jobType,
    this.experienceLevel,
    this.workingModel,
    this.salaryMin,
    this.salaryMax,
    this.currency,
    this.salaryPeriod,
    this.payoutFrequency,
    this.salaryDisplay = 'exact',
    this.ageMin,
    this.ageMax,
    this.preferredGender = 'any',
    this.startAvailability,
    this.schedulePattern,
    this.hoursPerDay,
    this.nightShift = false,
    this.formalization,
    this.womenFriendly = false,
    this.driverLicenses = const [],
    this.languages = const [],
    this.salaryGross = true,
    this.requireCoverLetter = false,
    this.disabilityFriendly = false,
    this.allowIncompleteResume = false,
    this.showPhoneOnListing = false,
    this.contactPhone,
    this.skills = const [],
    this.description,
    this.responsibilities,
    this.requirements,
    this.benefits,
    this.applicantsCount = 0,
    this.postedAt,
    this.categoryName,
    this.categoryId,
    this.status = 'open',
    this.boostedUntil,
    this.boostKind,
    this.expiresAt,
    this.publishAt,
    this.screeningQuestions = const [],
    this.educationRequired = 'none',
    this.workHours,
  });

  final String id;
  final String title;
  final String companyId;
  final String companyName;
  final String? companyLogoUrl;
  final bool companyVerified;
  final String? location;
  final String? addressText;
  final String? city;
  final String? country;

  /// Structured Uzbekistan location: region (viloyat) and district (tuman).
  final String? region;
  final String? district;

  final double? lat;
  final double? lng;
  final String? jobType;
  final String? experienceLevel;
  final String? workingModel;
  final num? salaryMin;
  final num? salaryMax;
  final String? currency;
  final String? salaryPeriod;

  /// How often wages are paid: `monthly` / `biweekly` / `weekly` / `daily`.
  final String? payoutFrequency;

  /// How the employer chose to display salary: `exact` | `negotiable` | `hidden`.
  final String salaryDisplay;

  /// Candidate age range requirements (optional).
  final int? ageMin;
  final int? ageMax;

  /// Employer's preference for applicant gender: `any` | `male` | `female`.
  final String preferredGender;

  /// When the employer expects the new hire to start: `immediate` | `one_week`
  /// | `two_weeks` | `one_month`.
  final String? startAvailability;

  /// Blue-collar fit: schedule pattern (`6_1`/`5_2`…), hours/day, night shifts,
  /// and how the hire is formalized (`employment_contract`/`gph`/…).
  final String? schedulePattern;
  final num? hoursPerDay;
  final bool nightShift;
  final String? formalization;

  /// Employer opt-in marker: the role offers women-friendly conditions
  /// (safe environment, flexible hours). Surfaced via the "Women-friendly"
  /// quick-find collection — not an exclusionary "women only" flag.
  final bool womenFriendly;

  /// Requirements (hh-style): driver-license categories (`B`/`C`/…), required
  /// [languages], and whether salaryMin/Max are gross (before tax) or net.
  final List<String> driverLicenses;
  final List<JobLanguage> languages;
  final bool salaryGross;

  /// Response settings (hh-style): require a cover letter on apply, an inclusive
  /// disability-friendly marker, accept candidates with an incomplete resume,
  /// and an optional [contactPhone] shown on the listing when [showPhoneOnListing].
  final bool requireCoverLetter;
  final bool disabilityFriendly;
  final bool allowIncompleteResume;
  final bool showPhoneOnListing;
  final String? contactPhone;
  final List<String> skills;
  final String? description;
  final String? responsibilities;
  final String? requirements;
  final String? benefits;
  final int applicantsCount;
  final DateTime? postedAt;
  final String? categoryName;
  final String? categoryId;

  /// Lifecycle: `draft` / `open` / `closed`. The seeker `job_feed` only ever
  /// returns `open`; employer reads of the base `jobs` table carry the real one.
  final String status;

  /// Paid promotion: when set in the future the job is "boosted" (TOP/featured).
  final DateTime? boostedUntil;
  final String? boostKind; // 'top' / 'featured'
  final DateTime? expiresAt;

  /// When set in the future, the job is scheduled: kept as a draft until
  /// `publish_at` (a backend cron flips it to `open` via `publish_due_jobs()`).
  final DateTime? publishAt;

  /// Screening questions authored on the posting; answers land in
  /// `applications.answers` keyed by each question's id.
  final List<ScreeningQuestion> screeningQuestions;

  /// Minimum education level required: `none` / `secondary` /
  /// `specialized_secondary` / `higher`.
  final String educationRequired;

  /// Working hours as a free-form string, e.g. "9:00–18:00".
  final String? workHours;

  /// True while a paid promotion is active.
  bool get isBoosted =>
      boostedUntil != null && boostedUntil!.isAfter(DateTime.now());

  String get locationText =>
      location ??
      [city, country].where((e) => e != null && e.isNotEmpty).join(', ');

  String get _currencySymbol => switch (currency) {
    'USD' => r'$',
    'EUR' => '€',
    'GBP' => '£',
    _ => (currency == null || currency!.isEmpty) ? '' : '${currency!} ',
  };

  /// e.g. r"$1.5k - $3k" (USD) or "2 500 000 - 3 000 000 so'm" (UZS). Null when
  /// no salary is set.
  String? get salaryText {
    final min = salaryMin;
    final max = salaryMax;
    if (currency == 'UZS') {
      String g(num v) => _groupDigits(v.round());
      if (min != null && max != null) return "${g(min)} - ${g(max)} so'm";
      final one = min ?? max;
      return one == null ? null : "${g(one)} so'm";
    }
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

  /// Space-grouped thousands, e.g. 2500000 -> "2 500 000".
  static String _groupDigits(int v) {
    final s = v.abs().toString();
    final buf = StringBuffer(v < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  // The salary-period suffix is localized in the presentation layer via
  // `salaryPeriodLabel(context, salaryPeriod)` (job_labels.dart).

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
      addressText: m['address_text'] as String?,
      city: m['city'] as String?,
      country: m['country'] as String?,
      region: m['region'] as String?,
      district: m['district'] as String?,
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      jobType: m['job_type'] as String?,
      experienceLevel: m['experience_level'] as String?,
      workingModel: m['working_model'] as String?,
      salaryMin: parseNum(m['salary_min']),
      salaryMax: parseNum(m['salary_max']),
      currency: m['currency'] as String?,
      salaryPeriod: m['salary_period'] as String?,
      payoutFrequency: m['payout_frequency'] as String?,
      salaryDisplay: (m['salary_display'] as String?) ?? 'exact',
      ageMin: (m['age_min'] as num?)?.toInt(),
      ageMax: (m['age_max'] as num?)?.toInt(),
      preferredGender: (m['preferred_gender'] as String?) ?? 'any',
      startAvailability: m['start_availability'] as String?,
      schedulePattern: m['schedule_pattern'] as String?,
      hoursPerDay: parseNum(m['hours_per_day']),
      nightShift: (m['night_shift'] ?? false) as bool,
      formalization: m['formalization'] as String?,
      womenFriendly: (m['women_friendly'] ?? false) as bool,
      driverLicenses:
          (m['driver_licenses'] as List?)?.map((e) => '$e').toList() ??
          const [],
      languages:
          (m['languages'] as List?)
              ?.map(
                (e) => JobLanguage.fromMap((e as Map).cast<String, dynamic>()),
              )
              .toList() ??
          const [],
      salaryGross: (m['salary_gross'] ?? true) as bool,
      requireCoverLetter: (m['require_cover_letter'] ?? false) as bool,
      disabilityFriendly: (m['disability_friendly'] ?? false) as bool,
      allowIncompleteResume: (m['allow_incomplete_resume'] ?? false) as bool,
      showPhoneOnListing: (m['show_phone_on_listing'] ?? false) as bool,
      contactPhone: m['contact_phone'] as String?,
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
      categoryId: m['category_id'] as String?,
      status: (m['status'] ?? 'open') as String,
      boostedUntil: m['boosted_until'] != null
          ? DateTime.tryParse('${m['boosted_until']}')
          : null,
      boostKind: m['boost_kind'] as String?,
      expiresAt: m['expires_at'] != null
          ? DateTime.tryParse('${m['expires_at']}')
          : null,
      publishAt: m['publish_at'] != null
          ? DateTime.tryParse('${m['publish_at']}')
          : null,
      screeningQuestions:
          (m['screening_questions'] as List?)
              ?.map(
                (e) => ScreeningQuestion.fromMap(
                  (e as Map).cast<String, dynamic>(),
                ),
              )
              .toList() ??
          const [],
      educationRequired: (m['education_required'] as String?) ?? 'none',
      workHours: m['work_hours'] as String?,
    );
  }

  /// Sentinel so [copyWith] can distinguish "leave unchanged" from "set to
  /// null" for nullable fields (e.g. un-scheduling a job, clearing max salary).
  static const Object _unset = Object();

  Job copyWith({
    String? id,
    String? title,
    String? companyId,
    String? companyName,
    String? companyLogoUrl,
    bool? companyVerified,
    String? location,
    String? addressText,
    String? city,
    String? country,
    String? region,
    String? district,
    double? lat,
    double? lng,
    String? jobType,
    String? experienceLevel,
    String? workingModel,
    Object? salaryMin = _unset,
    Object? salaryMax = _unset,
    String? currency,
    String? salaryPeriod,
    String? payoutFrequency,
    String? salaryDisplay,
    Object? ageMin = _unset,
    Object? ageMax = _unset,
    String? preferredGender,
    String? startAvailability,
    String? schedulePattern,
    num? hoursPerDay,
    bool? nightShift,
    String? formalization,
    bool? womenFriendly,
    List<String>? driverLicenses,
    List<JobLanguage>? languages,
    bool? salaryGross,
    bool? requireCoverLetter,
    bool? disabilityFriendly,
    bool? allowIncompleteResume,
    bool? showPhoneOnListing,
    String? contactPhone,
    List<String>? skills,
    String? description,
    String? responsibilities,
    String? requirements,
    String? benefits,
    int? applicantsCount,
    DateTime? postedAt,
    String? categoryName,
    String? categoryId,
    String? status,
    DateTime? boostedUntil,
    String? boostKind,
    DateTime? expiresAt,
    Object? publishAt = _unset,
    List<ScreeningQuestion>? screeningQuestions,
    String? educationRequired,
    String? workHours,
  }) => Job(
    id: id ?? this.id,
    title: title ?? this.title,
    companyId: companyId ?? this.companyId,
    companyName: companyName ?? this.companyName,
    companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
    companyVerified: companyVerified ?? this.companyVerified,
    location: location ?? this.location,
    addressText: addressText ?? this.addressText,
    city: city ?? this.city,
    country: country ?? this.country,
    region: region ?? this.region,
    district: district ?? this.district,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    jobType: jobType ?? this.jobType,
    experienceLevel: experienceLevel ?? this.experienceLevel,
    workingModel: workingModel ?? this.workingModel,
    salaryMin: salaryMin == _unset ? this.salaryMin : salaryMin as num?,
    salaryMax: salaryMax == _unset ? this.salaryMax : salaryMax as num?,
    currency: currency ?? this.currency,
    salaryPeriod: salaryPeriod ?? this.salaryPeriod,
    payoutFrequency: payoutFrequency ?? this.payoutFrequency,
    salaryDisplay: salaryDisplay ?? this.salaryDisplay,
    ageMin: ageMin == _unset ? this.ageMin : ageMin as int?,
    ageMax: ageMax == _unset ? this.ageMax : ageMax as int?,
    preferredGender: preferredGender ?? this.preferredGender,
    startAvailability: startAvailability ?? this.startAvailability,
    schedulePattern: schedulePattern ?? this.schedulePattern,
    hoursPerDay: hoursPerDay ?? this.hoursPerDay,
    nightShift: nightShift ?? this.nightShift,
    formalization: formalization ?? this.formalization,
    womenFriendly: womenFriendly ?? this.womenFriendly,
    driverLicenses: driverLicenses ?? this.driverLicenses,
    languages: languages ?? this.languages,
    salaryGross: salaryGross ?? this.salaryGross,
    requireCoverLetter: requireCoverLetter ?? this.requireCoverLetter,
    disabilityFriendly: disabilityFriendly ?? this.disabilityFriendly,
    allowIncompleteResume: allowIncompleteResume ?? this.allowIncompleteResume,
    showPhoneOnListing: showPhoneOnListing ?? this.showPhoneOnListing,
    contactPhone: contactPhone ?? this.contactPhone,
    skills: skills ?? this.skills,
    description: description ?? this.description,
    responsibilities: responsibilities ?? this.responsibilities,
    requirements: requirements ?? this.requirements,
    benefits: benefits ?? this.benefits,
    applicantsCount: applicantsCount ?? this.applicantsCount,
    postedAt: postedAt ?? this.postedAt,
    categoryName: categoryName ?? this.categoryName,
    categoryId: categoryId ?? this.categoryId,
    status: status ?? this.status,
    boostedUntil: boostedUntil ?? this.boostedUntil,
    boostKind: boostKind ?? this.boostKind,
    expiresAt: expiresAt ?? this.expiresAt,
    publishAt: publishAt == _unset ? this.publishAt : publishAt as DateTime?,
    screeningQuestions: screeningQuestions ?? this.screeningQuestions,
    educationRequired: educationRequired ?? this.educationRequired,
    workHours: workHours ?? this.workHours,
  );
}
