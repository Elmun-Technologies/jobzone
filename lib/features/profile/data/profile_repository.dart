import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/enums/enums.dart';
import '../domain/user_profile.dart';
import 'cv_repository.dart';
import 'offline_profile.dart';

SeekingStatus _seekingStatusFromId(int? id) => switch (id) {
  2 => SeekingStatus.openToOffers,
  3 => SeekingStatus.notLooking,
  _ => SeekingStatus.activelyLooking,
};

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

  /// Offline profile assembled from the shared scalar store plus the CV lists
  /// owned by [CvRepository], so edits made on the edit screens are reflected.
  Future<UserProfile> _offlineProfile() async {
    final cv = _ref.read(cvRepositoryProvider);
    final exps = await cv.experiences();
    final edus = await cv.educations();
    final skills = await cv.skills();
    String? years(DateTime? s, DateTime? e, bool current) {
      final start = s?.year.toString();
      final end = current ? 'Present' : e?.year.toString();
      if (start == null && end == null) return null;
      return [start, end].where((x) => x != null).join(' – ');
    }

    return UserProfile(
      fullName: offlineProfile.fullName,
      headline: offlineProfile.headline,
      bio: offlineProfile.bio,
      avatarUrl: offlineProfile.avatarUrl,
      city: offlineProfile.city,
      country: offlineProfile.country,
      email: offlineProfile.email,
      phone: offlineProfile.phone,
      isOpenToWork: offlineProfile.isOpenToWork,
      seekingStatus: offlineProfile.seekingStatus,
      experiences: [
        for (final e in exps)
          ExperienceEntry(
            title: e.title,
            companyName: e.companyName,
            period: years(e.startDate, e.endDate, e.isCurrent),
            description: e.description,
          ),
      ],
      educations: [
        for (final e in edus)
          EducationEntry(
            school: e.school,
            degree: e.degree,
            period: years(e.startDate, e.endDate, false),
          ),
      ],
      skills: skills,
    );
  }

  Future<UserProfile?> load() async {
    if (!Env.hasSupabase) return _offlineProfile();

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
      seekingStatus: _seekingStatusFromId(p['seeking_status_id'] as int?),
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
