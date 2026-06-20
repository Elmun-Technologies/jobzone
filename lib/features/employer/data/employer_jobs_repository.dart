import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../jobs/domain/job.dart';
import 'mock_employer.dart';

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
    String? city,
    String? country,
    List<String> skills = const [],
    String? description,
    String? responsibilities,
    String? requirements,
    String? benefits,
    String status = 'open',
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
        currency: 'USD',
        salaryPeriod: salaryPeriod ?? 'month',
        payoutFrequency: payoutFrequency,
        city: city,
        country: country,
        skills: skills,
        description: description,
        responsibilities: responsibilities,
        requirements: requirements,
        benefits: benefits,
        postedAt: DateTime.now(),
        status: status,
      );
      mockEmployer.jobs.insert(0, job);
      return job;
    }
    final client = _ref.read(supabaseClientProvider);
    final company = await _ownedCompany();
    final uid = client.auth.currentUser?.id;
    final row = await client
        .from('jobs')
        .insert({
          'company_id': company?['id'],
          'posted_by': uid,
          'title': title,
          'status': status,
          'skills_required': skills,
          'job_type': ?jobType,
          'experience_level': ?experienceLevel,
          'working_model': ?workingModel,
          'salary_min': ?salaryMin,
          'salary_max': ?salaryMax,
          'salary_period': ?salaryPeriod,
          'payout_frequency': ?payoutFrequency,
          if (city != null && city.isNotEmpty) 'city': city,
          if (country != null && country.isNotEmpty) 'country': country,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (responsibilities != null && responsibilities.isNotEmpty)
            'responsibilities': responsibilities,
          if (requirements != null && requirements.isNotEmpty)
            'requirements': requirements,
          if (benefits != null && benefits.isNotEmpty) 'benefits': benefits,
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
          'salary_period': job.salaryPeriod,
          'payout_frequency': job.payoutFrequency,
          'city': job.city,
          'country': job.country,
          'skills_required': job.skills,
          'description': job.description,
          'responsibilities': job.responsibilities,
          'requirements': job.requirements,
          'benefits': job.benefits,
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
