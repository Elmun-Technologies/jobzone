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
