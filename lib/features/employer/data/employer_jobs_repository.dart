import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../jobs/data/categories_repository.dart';
import '../../jobs/domain/job.dart';
import '../../jobs/domain/job_language.dart';
import '../../jobs/domain/screening_question.dart';
import 'mock_employer.dart';

/// Thrown when a job write is attempted before the employer has a company —
/// `jobs.company_id` is NOT NULL. The UI catches this to steer the user into
/// the create-company step instead of surfacing a raw DB error.
class NoCompanyError implements Exception {
  const NoCompanyError();
  @override
  String toString() => 'NoCompanyError';
}

/// Write-side jobs repository for employers: list, create, edit and open/close
/// the jobs owned by the employer's company. Owner CRUD on `jobs` is permitted
/// by the `is_job_owner` RLS helper. Falls back to an in-memory store (seeded
/// from the c-acme mock jobs) when no backend is configured.
class EmployerJobsRepository {
  EmployerJobsRepository(this._ref);

  final Ref _ref;

  bool get _live => Env.hasSupabase;

  /// The employer's jobs, newest first, optionally filtered by [status].
  Future<List<Job>> myJobs({String? status}) async {
    if (!_live) {
      final jobs = mockEmployer.jobs;
      return [
        for (final j in jobs)
          if (status == null || j.status == status) j,
      ];
    }
    final client = _ref.read(supabaseClientProvider);
    final company = await _ownedCompany();
    if (company == null) return const [];
    final base = client.from('jobs').select().eq('company_id', company['id']);
    final filtered = status == null ? base : base.eq('status', status);
    final rows = await filtered.order('posted_at', ascending: false);
    return (rows as List)
        .map(
          (r) => Job.fromMap(_withCompany(r as Map<String, dynamic>, company)),
        )
        .toList();
  }

  /// Creates a job for the employer's company and returns it.
  Future<Job> createJob({
    required String title,
    String? jobType,
    String? experienceLevel,
    String? workingModel,
    num? salaryMin,
    num? salaryMax,
    String? salaryPeriod,
    String? payoutFrequency,
    String salaryDisplay = 'exact',
    int? ageMin,
    int? ageMax,
    String preferredGender = 'any',
    String? startAvailability,
    String? schedulePattern,
    num? hoursPerDay,
    bool nightShift = false,
    String? formalization,
    bool womenFriendly = false,
    List<String> driverLicenses = const [],
    List<JobLanguage> languages = const [],
    bool salaryGross = true,
    bool requireCoverLetter = false,
    bool disabilityFriendly = false,
    bool allowIncompleteResume = false,
    bool showPhoneOnListing = false,
    String? contactPhone,
    String currency = 'UZS',
    String? categoryId,
    double? lat,
    double? lng,
    String? addressText,
    String? city,
    String? country,
    String? region,
    String? district,
    List<String> skills = const [],
    String? description,
    String? responsibilities,
    String? requirements,
    String? benefits,
    List<ScreeningQuestion> screeningQuestions = const [],
    String status = 'open',
    DateTime? publishAt,
    String educationRequired = 'none',
    String? workHours,
  }) async {
    if (!_live) {
      final job = Job(
        id: 'emp-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        companyId: MockEmployer.companyId,
        companyName: mockEmployer.company?.name ?? 'Acme',
        companyVerified: mockEmployer.company?.isVerified ?? true,
        jobType: jobType,
        experienceLevel: experienceLevel,
        workingModel: workingModel,
        salaryMin: salaryMin,
        salaryMax: salaryMax,
        currency: currency,
        salaryPeriod: salaryPeriod ?? 'month',
        payoutFrequency: payoutFrequency,
        salaryDisplay: salaryDisplay,
        ageMin: ageMin,
        ageMax: ageMax,
        preferredGender: preferredGender,
        startAvailability: startAvailability,
        schedulePattern: schedulePattern,
        hoursPerDay: hoursPerDay,
        nightShift: nightShift,
        formalization: formalization,
        womenFriendly: womenFriendly,
        driverLicenses: driverLicenses,
        languages: languages,
        salaryGross: salaryGross,
        requireCoverLetter: requireCoverLetter,
        disabilityFriendly: disabilityFriendly,
        allowIncompleteResume: allowIncompleteResume,
        showPhoneOnListing: showPhoneOnListing,
        contactPhone: contactPhone,
        categoryId: categoryId,
        categoryName: CategoriesRepository.byId(categoryId)?.name,
        city: city,
        country: country,
        region: region,
        district: district,
        lat: lat,
        lng: lng,
        addressText: addressText,
        skills: skills,
        description: description,
        responsibilities: responsibilities,
        requirements: requirements,
        benefits: benefits,
        screeningQuestions: screeningQuestions,
        postedAt: DateTime.now(),
        publishAt: publishAt,
        status: status,
        educationRequired: educationRequired,
        workHours: workHours,
      );
      mockEmployer.jobs.insert(0, job);
      return job;
    }
    final client = _ref.read(supabaseClientProvider);
    final company = await _ownedCompany();
    // jobs.company_id is NOT NULL. Without a company we'd hit a raw 23502
    // "null value in company_id" that surfaces as "Something went wrong";
    // fail fast with a typed marker the UI localizes into "create your
    // company first".
    if (company == null) throw const NoCompanyError();
    final uid = client.auth.currentUser?.id;
    final row = await client
        .from('jobs')
        .insert({
          'company_id': company['id'],
          'posted_by': uid,
          'title': title,
          'status': status,
          'publish_at': ?publishAt?.toIso8601String(),
          'skills_required': skills,
          'job_type': ?jobType,
          'experience_level': ?experienceLevel,
          'working_model': ?workingModel,
          'salary_min': ?salaryMin,
          'salary_max': ?salaryMax,
          'currency': currency,
          'salary_period': ?salaryPeriod,
          'payout_frequency': ?payoutFrequency,
          'salary_display': salaryDisplay,
          'age_min': ?ageMin,
          'age_max': ?ageMax,
          'preferred_gender': preferredGender,
          'start_availability': ?startAvailability,
          'region': ?region,
          'district': ?district,
          'schedule_pattern': ?schedulePattern,
          'hours_per_day': ?hoursPerDay,
          'night_shift': nightShift,
          'formalization': ?formalization,
          'women_friendly': womenFriendly,
          'driver_licenses': driverLicenses,
          'languages': languages.map((e) => e.toMap()).toList(),
          'salary_gross': salaryGross,
          'require_cover_letter': requireCoverLetter,
          'disability_friendly': disabilityFriendly,
          'allow_incomplete_resume': allowIncompleteResume,
          'show_phone_on_listing': showPhoneOnListing,
          'contact_phone': ?contactPhone,
          'category_id': ?categoryId,
          'lat': ?lat,
          'lng': ?lng,
          'address_text': ?addressText,
          if (city != null && city.isNotEmpty) 'city': city,
          if (country != null && country.isNotEmpty) 'country': country,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (responsibilities != null && responsibilities.isNotEmpty)
            'responsibilities': responsibilities,
          if (requirements != null && requirements.isNotEmpty)
            'requirements': requirements,
          if (benefits != null && benefits.isNotEmpty) 'benefits': benefits,
          'screening_questions': screeningQuestions
              .map((q) => q.toMap())
              .toList(),
          'education_required': educationRequired,
          'work_hours': ?workHours,
        })
        .select()
        .single();
    return Job.fromMap(_withCompany(row, company));
  }

  /// Updates an existing job and returns the new value.
  Future<Job> updateJob(Job job) async {
    if (!_live) {
      final jobs = mockEmployer.jobs;
      final i = jobs.indexWhere((j) => j.id == job.id);
      if (i >= 0) jobs[i] = job;
      return job;
    }
    final client = _ref.read(supabaseClientProvider);
    final company = await _ownedCompany();
    final row = await client
        .from('jobs')
        .update({
          'title': job.title,
          'job_type': job.jobType,
          'experience_level': job.experienceLevel,
          'working_model': job.workingModel,
          'salary_min': job.salaryMin,
          'salary_max': job.salaryMax,
          'currency': job.currency,
          'salary_period': job.salaryPeriod,
          'payout_frequency': job.payoutFrequency,
          'salary_display': job.salaryDisplay,
          'age_min': job.ageMin,
          'age_max': job.ageMax,
          'preferred_gender': job.preferredGender,
          'start_availability': job.startAvailability,
          'region': job.region,
          'district': job.district,
          'schedule_pattern': job.schedulePattern,
          'hours_per_day': job.hoursPerDay,
          'night_shift': job.nightShift,
          'formalization': job.formalization,
          'women_friendly': job.womenFriendly,
          'driver_licenses': job.driverLicenses,
          'languages': job.languages.map((e) => e.toMap()).toList(),
          'salary_gross': job.salaryGross,
          'require_cover_letter': job.requireCoverLetter,
          'disability_friendly': job.disabilityFriendly,
          'allow_incomplete_resume': job.allowIncompleteResume,
          'show_phone_on_listing': job.showPhoneOnListing,
          'contact_phone': job.contactPhone,
          'publish_at': job.publishAt?.toIso8601String(),
          'category_id': job.categoryId,
          'lat': job.lat,
          'lng': job.lng,
          'address_text': job.addressText,
          'city': job.city,
          'country': job.country,
          'skills_required': job.skills,
          'description': job.description,
          'responsibilities': job.responsibilities,
          'requirements': job.requirements,
          'benefits': job.benefits,
          'screening_questions': job.screeningQuestions
              .map((q) => q.toMap())
              .toList(),
          'education_required': job.educationRequired,
          'work_hours': job.workHours,
        })
        .eq('id', job.id)
        .select()
        .single();
    return Job.fromMap(_withCompany(row, company));
  }

  /// Flips a job's lifecycle status (`draft` / `open` / `closed`).
  Future<void> setStatus(String jobId, String status) async {
    if (!_live) {
      final jobs = mockEmployer.jobs;
      final i = jobs.indexWhere((j) => j.id == jobId);
      if (i >= 0) jobs[i] = jobs[i].copyWith(status: status);
      return;
    }
    await _ref
        .read(supabaseClientProvider)
        .from('jobs')
        .update({'status': status})
        .eq('id', jobId);
  }

  Future<Map<String, dynamic>?> _ownedCompany() async {
    final client = _ref.read(supabaseClientProvider);
    final uid = client.auth.currentUser?.id;
    if (uid == null) return null;
    return client
        .from('companies')
        .select('id, name, logo_url, is_verified')
        .eq('owner_id', uid)
        .maybeSingle();
  }

  /// The base `jobs` row lacks the flattened company display fields the [Job]
  /// model expects; inject them from the owning company.
  Map<String, dynamic> _withCompany(
    Map<String, dynamic> row,
    Map<String, dynamic>? company,
  ) {
    if (company == null) return row;
    return {
      ...row,
      'company_name': company['name'],
      'company_logo_url': company['logo_url'],
      'company_is_verified': company['is_verified'],
    };
  }
}

final employerJobsRepositoryProvider = Provider<EmployerJobsRepository>(
  (ref) => EmployerJobsRepository(ref),
);

/// The employer's jobs, optionally filtered by status (`open`/`draft`/`closed`).
final myJobsProvider = FutureProvider.family<List<Job>, String?>(
  (ref, status) =>
      ref.read(employerJobsRepositoryProvider).myJobs(status: status),
);
