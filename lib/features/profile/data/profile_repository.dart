import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/user_profile.dart';

String? _yearRange(Object? start, Object? end, bool current) {
  String? year(Object? d) {
    if (d == null) return null;
    final s = '$d';
    return s.length >= 4 ? s.substring(0, 4) : s;
  }

  final s = year(start);
  final e = current ? 'Present' : year(end);
  if (s == null && e == null) return null;
  return [s, e].where((x) => x != null).join(' – ');
}

/// Loads the signed-in user's profile + key CV sections. Serves a sample
/// profile when no backend is configured (offline mode).
class ProfileRepository {
  ProfileRepository(this._ref);

  final Ref _ref;

  Future<UserProfile?> load() async {
    if (!Env.hasSupabase) return _mockProfile;

    final client = _ref.read(supabaseClientProvider);
    final uid = client.auth.currentUser?.id;
    if (uid == null) return null;

    final p = await client
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();
    if (p == null) return null;

    final exp = await client
        .from('experiences')
        .select()
        .eq('profile_id', uid)
        .order('start_date', ascending: false);
    final edu = await client
        .from('educations')
        .select()
        .eq('profile_id', uid)
        .order('start_date', ascending: false);
    final skillRows = await client
        .from('profile_skills')
        .select('skills(name)')
        .eq('profile_id', uid);

    return UserProfile(
      fullName: p['full_name'] as String?,
      headline: p['headline'] as String?,
      bio: p['bio'] as String?,
      avatarUrl: p['avatar_url'] as String?,
      city: p['city'] as String?,
      country: p['country'] as String?,
      email: p['email'] as String?,
      phone: p['phone'] as String?,
      isOpenToWork: (p['is_open_to_work'] ?? true) as bool,
      experiences: (exp as List)
          .map(
            (e) => ExperienceEntry(
              title: (e['title'] ?? '') as String,
              companyName: e['company_name'] as String?,
              period: _yearRange(
                e['start_date'],
                e['end_date'],
                (e['is_current'] ?? false) as bool,
              ),
              description: e['description'] as String?,
            ),
          )
          .toList(),
      educations: (edu as List)
          .map(
            (e) => EducationEntry(
              school: (e['school'] ?? '') as String,
              degree: e['degree'] as String?,
              period: _yearRange(e['start_date'], e['end_date'], false),
            ),
          )
          .toList(),
      skills: (skillRows as List)
          .map((e) {
            final s = e['skills'];
            return s is Map ? (s['name'] as String? ?? '') : '';
          })
          .where((s) => s.isNotEmpty)
          .toList(),
    );
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref),
);

final currentProfileProvider = FutureProvider<UserProfile?>(
  (ref) => ref.watch(profileRepositoryProvider).load(),
);

const _mockProfile = UserProfile(
  fullName: 'Aziz Karimov',
  headline: 'Senior Flutter Engineer',
  bio: 'Mobile engineer focused on clean architecture and delightful UX.',
  city: 'Tashkent',
  country: 'UZ',
  email: 'aziz@example.com',
  phone: '+998 90 123 45 67',
  experiences: [
    ExperienceEntry(
      title: 'Senior Flutter Engineer',
      companyName: 'Acme',
      period: '2022 – Present',
      description: 'Lead the mobile team building cross-platform apps.',
    ),
    ExperienceEntry(
      title: 'Mobile Developer',
      companyName: 'Nimbus',
      period: '2019 – 2022',
    ),
  ],
  educations: [
    EducationEntry(
      school: 'TUIT',
      degree: 'BSc Computer Science',
      period: '2015 – 2019',
    ),
  ],
  skills: ['Dart', 'Flutter', 'Riverpod', 'Supabase', 'REST', 'Git'],
);
