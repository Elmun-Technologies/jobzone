import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../companies/domain/company.dart';
import 'mock_employer.dart';

/// Write-side companion to [CompaniesRepository]: lets an employer create and
/// manage their own company (`owner_id = auth.uid()`; RLS permits owner CRUD).
/// Falls back to an in-memory store when no backend is configured so the flow
/// is demoable and unit-testable offline.
class CompanyAdminRepository {
  CompanyAdminRepository(this._ref);

  final Ref _ref;

  bool get _live => Env.hasSupabase;

  /// The company owned by the current employer, if any.
  Future<Company?> myCompany() async {
    if (!_live) return mockEmployer.company;
    final client = _ref.read(supabaseClientProvider);
    final uid = client.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await client
        .from('companies')
        .select()
        .eq('owner_id', uid)
        .limit(1)
        .maybeSingle();
    return row == null ? null : Company.fromMap(row);
  }

  /// Creates the employer's company and returns it.
  Future<Company> createCompany({
    required String name,
    String? industry,
    String? size,
    String? about,
    String? website,
    String? headquarters,
  }) async {
    if (!_live) {
      final company = Company(
        id: MockEmployer.companyId,
        name: name,
        industry: industry,
        size: size,
        about: about,
        website: website,
        headquarters: headquarters,
      );
      mockEmployer.company = company;
      return company;
    }
    final client = _ref.read(supabaseClientProvider);
    final uid = client.auth.currentUser!.id;
    // Idempotent: a second create for the same owner would brick the employer
    // area (myCompany() then sees two rows). Return the existing one instead;
    // a unique index on owner_id (migration 0028) enforces this server-side too.
    final existing = await myCompany();
    if (existing != null) return existing;
    final row = await client
        .from('companies')
        .insert({
          'name': name,
          'slug': _slugify(name),
          'owner_id': uid,
          if (industry != null && industry.isNotEmpty) 'industry': industry,
          if (size != null && size.isNotEmpty) 'size': size,
          if (about != null && about.isNotEmpty) 'about': about,
          if (website != null && website.isNotEmpty) 'website': website,
          if (headquarters != null && headquarters.isNotEmpty)
            'headquarters': headquarters,
        })
        .select()
        .single();
    return Company.fromMap(row);
  }

  /// Updates the employer's company profile and returns the new value.
  Future<Company> updateCompany(Company company) async {
    if (!_live) {
      mockEmployer.company = company;
      return company;
    }
    final client = _ref.read(supabaseClientProvider);
    final row = await client
        .from('companies')
        .update({
          'name': company.name,
          'industry': company.industry,
          'size': company.size,
          'about': company.about,
          'website': company.website,
          'headquarters': company.headquarters,
        })
        .eq('id', company.id)
        .select()
        .single();
    return Company.fromMap(row);
  }

  // ── People (team / recruiters) ─────────────────────────────────────────────

  Future<List<CompanyPerson>> people() async {
    if (!_live) return [...mockEmployer.people];
    final client = _ref.read(supabaseClientProvider);
    final company = await myCompany();
    if (company == null) return const [];
    final rows = await client
        .from('company_people')
        .select()
        .eq('company_id', company.id)
        .order('is_recruiter', ascending: false);
    return (rows as List)
        .map((e) => CompanyPerson.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addPerson({
    required String name,
    String? title,
    bool isRecruiter = false,
  }) async {
    if (!_live) {
      mockEmployer.people.add(
        CompanyPerson(
          id: 'mp-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          title: title,
          isRecruiter: isRecruiter,
        ),
      );
      return;
    }
    final company = await myCompany();
    await _ref.read(supabaseClientProvider).from('company_people').insert({
      'company_id': company?.id,
      'name': name,
      'is_recruiter': isRecruiter,
      if (title != null && title.isNotEmpty) 'title': title,
    });
  }

  Future<void> removePerson(String id) async {
    if (!_live) {
      mockEmployer.people.removeWhere((p) => p.id == id);
      return;
    }
    await _ref
        .read(supabaseClientProvider)
        .from('company_people')
        .delete()
        .eq('id', id);
  }

  // ── Gallery ────────────────────────────────────────────────────────────────

  Future<List<GalleryItem>> gallery() async {
    if (!_live) return [...mockEmployer.gallery];
    final client = _ref.read(supabaseClientProvider);
    final company = await myCompany();
    if (company == null) return const [];
    final rows = await client
        .from('company_gallery')
        .select()
        .eq('company_id', company.id)
        .order('sort_order');
    return (rows as List)
        .map((e) => GalleryItem.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addGalleryItem({
    required String mediaUrl,
    String? caption,
  }) async {
    if (!_live) {
      mockEmployer.gallery.add(
        GalleryItem(
          id: 'mg-${DateTime.now().millisecondsSinceEpoch}',
          mediaUrl: mediaUrl,
          caption: caption,
        ),
      );
      return;
    }
    final company = await myCompany();
    await _ref.read(supabaseClientProvider).from('company_gallery').insert({
      'company_id': company?.id,
      'media_url': mediaUrl,
      'media_type': 'image',
      if (caption != null && caption.isNotEmpty) 'caption': caption,
    });
  }

  Future<void> removeGalleryItem(String id) async {
    if (!_live) {
      mockEmployer.gallery.removeWhere((g) => g.id == id);
      return;
    }
    await _ref
        .read(supabaseClientProvider)
        .from('company_gallery')
        .delete()
        .eq('id', id);
  }

  /// Lowercased, hyphenated name plus a short timestamp suffix so the unique
  /// `companies.slug` constraint never collides.
  String _slugify(String name) {
    final base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final suffix = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return base.isEmpty ? 'company-$suffix' : '$base-$suffix';
  }
}

final companyAdminRepositoryProvider = Provider<CompanyAdminRepository>(
  (ref) => CompanyAdminRepository(ref),
);

/// The current employer's company (null until create-company onboarding runs).
final myCompanyProvider = FutureProvider<Company?>(
  (ref) => ref.read(companyAdminRepositoryProvider).myCompany(),
);

/// The employer's team / recruiters.
final companyPeopleAdminProvider = FutureProvider<List<CompanyPerson>>(
  (ref) => ref.read(companyAdminRepositoryProvider).people(),
);

/// The employer's company gallery.
final companyGalleryAdminProvider = FutureProvider<List<GalleryItem>>(
  (ref) => ref.read(companyAdminRepositoryProvider).gallery(),
);
