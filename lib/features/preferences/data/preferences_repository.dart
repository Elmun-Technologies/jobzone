import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';

/// Persists the user's job-search preferences to `user_preferences`.
class PreferencesRepository {
  PreferencesRepository(this._client);

  final SupabaseClient _client;

  Future<void> save({
    required List<String> jobTypes,
    required List<String> experienceLevels,
    required List<String> workingModels,
    required List<String> titles,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('user_preferences').upsert({
      'profile_id': uid,
      'job_types': jobTypes,
      'experience_levels': experienceLevels,
      'working_models': workingModels,
      'desired_titles': titles,
    });
  }
}

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepository(ref.watch(supabaseClientProvider));
});
