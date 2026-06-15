import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/company.dart';

/// Reads company profiles, people and gallery. Serves sample data (matching
/// the mock jobs' `companyId`s) when no backend is configured.
class CompaniesRepository {
  CompaniesRepository(this._ref);

  final Ref _ref;

  bool get _live => Env.hasSupabase;

  Future<Company?> byId(String id) async {
    if (!_live) return _mockCompanies[id];
    final row = await _ref
        .read(supabaseClientProvider)
        .from('companies')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Company.fromMap(row);
  }

  Future<List<CompanyPerson>> people(String companyId) async {
    if (!_live) return _mockPeople[companyId] ?? const [];
    final rows = await _ref
        .read(supabaseClientProvider)
        .from('company_people')
        .select()
        .eq('company_id', companyId)
        .order('is_recruiter', ascending: false);
    return (rows as List)
        .map((e) => CompanyPerson.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GalleryItem>> gallery(String companyId) async {
    if (!_live) return _mockGallery[companyId] ?? const [];
    final rows = await _ref
        .read(supabaseClientProvider)
        .from('company_gallery')
        .select()
        .eq('company_id', companyId)
        .order('sort_order');
    return (rows as List)
        .map((e) => GalleryItem.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}

final companiesRepositoryProvider = Provider<CompaniesRepository>(
  (ref) => CompaniesRepository(ref),
);

final companyByIdProvider = FutureProvider.family<Company?, String>(
  (ref, id) => ref.read(companiesRepositoryProvider).byId(id),
);

final companyPeopleProvider =
    FutureProvider.family<List<CompanyPerson>, String>(
      (ref, id) => ref.read(companiesRepositoryProvider).people(id),
    );

final companyGalleryProvider = FutureProvider.family<List<GalleryItem>, String>(
  (ref, id) => ref.read(companiesRepositoryProvider).gallery(id),
);

// --- Offline sample data -----------------------------------------------------
// A short, freely-usable sample clip for the intro-video player demo.
const _sampleVideo =
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4';

const _mockCompanies = <String, Company>{
  'c-acme': Company(
    id: 'c-acme',
    name: 'Acme',
    about:
        'Acme builds cross-platform mobile products used by millions across '
        'Central Asia. We are remote-first and obsessed with craft.',
    industry: 'Software',
    size: '201–500',
    foundedYear: 2015,
    website: 'https://acme.example.com',
    headquarters: 'Tashkent, UZ',
    introVideoUrl: _sampleVideo,
    isVerified: true,
    coverUrl: 'https://picsum.photos/seed/acme-cover/800/400',
    logoUrl: 'https://picsum.photos/seed/acme-logo/200/200',
  ),
  'c-nimbus': Company(
    id: 'c-nimbus',
    name: 'Nimbus',
    about:
        'Nimbus is a design-led studio crafting delightful digital products '
        'for fast-growing startups.',
    industry: 'Design',
    size: '51–200',
    foundedYear: 2018,
    website: 'https://nimbus.example.com',
    headquarters: 'Remote',
    coverUrl: 'https://picsum.photos/seed/nimbus-cover/800/400',
    logoUrl: 'https://picsum.photos/seed/nimbus-logo/200/200',
  ),
};

const _mockPeople = <String, List<CompanyPerson>>{
  'c-acme': [
    CompanyPerson(
      id: 'p1',
      name: 'Dilnoza Yusupova',
      title: 'Head of Talent',
      isRecruiter: true,
      avatarUrl: 'https://picsum.photos/seed/p1/200/200',
    ),
    CompanyPerson(
      id: 'p2',
      name: 'Sardor Aliyev',
      title: 'Engineering Manager',
      avatarUrl: 'https://picsum.photos/seed/p2/200/200',
    ),
  ],
  'c-nimbus': [
    CompanyPerson(
      id: 'p3',
      name: 'Kamila Rashidova',
      title: 'Design Lead',
      isRecruiter: true,
      avatarUrl: 'https://picsum.photos/seed/p3/200/200',
    ),
  ],
};

const _mockGallery = <String, List<GalleryItem>>{
  'c-acme': [
    GalleryItem(
      id: 'g1',
      mediaUrl: 'https://picsum.photos/seed/acme1/600/600',
      caption: 'Our Tashkent office',
    ),
    GalleryItem(
      id: 'g2',
      mediaUrl: 'https://picsum.photos/seed/acme2/600/600',
      caption: 'Team offsite',
    ),
    GalleryItem(id: 'g3', mediaUrl: 'https://picsum.photos/seed/acme3/600/600'),
    GalleryItem(id: 'g4', mediaUrl: 'https://picsum.photos/seed/acme4/600/600'),
  ],
  'c-nimbus': [
    GalleryItem(
      id: 'g5',
      mediaUrl: 'https://picsum.photos/seed/nimbus1/600/600',
      caption: 'Studio',
    ),
    GalleryItem(
      id: 'g6',
      mediaUrl: 'https://picsum.photos/seed/nimbus2/600/600',
    ),
  ],
};
