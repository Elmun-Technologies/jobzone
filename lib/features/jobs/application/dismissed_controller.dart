import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/storage/local_cache.dart';
import '../../../core/supabase/supabase_providers.dart';

/// Holds the set of "archived" / not-interested job ids — mirrors
/// [BookmarksController] exactly (same `dismissed_jobs` shape as `bookmarks`,
/// 0052). Excluding these from the open-jobs feed is the seeker's control over
/// what keeps surfacing on Home; a dismissed job stays reachable if bookmarked
/// or linked to directly.
class DismissedController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    if (Env.hasSupabase) {
      final client = ref.read(supabaseClientProvider);
      final uid = client.auth.currentUser?.id;
      if (uid == null) return <String>{};
      final rows = await client
          .from('dismissed_jobs')
          .select('job_id')
          .eq('profile_id', uid);
      return rows.map<String>((r) => r['job_id'] as String).toSet();
    }
    final prefs = ref.read(sharedPreferencesProvider);
    return (prefs.getStringList(CacheKeys.dismissedJobs) ?? const <String>[])
        .toSet();
  }

  bool isDismissed(String jobId) => state.value?.contains(jobId) ?? false;

  Future<void> toggle(String jobId) async {
    final current = <String>{...?state.value};
    final adding = !current.contains(jobId);
    if (adding) {
      current.add(jobId);
    } else {
      current.remove(jobId);
    }
    state = AsyncData(current); // optimistic

    try {
      if (Env.hasSupabase) {
        final client = ref.read(supabaseClientProvider);
        final uid = client.auth.currentUser?.id;
        if (uid != null) {
          if (adding) {
            await client.from('dismissed_jobs').insert({
              'profile_id': uid,
              'job_id': jobId,
            });
          } else {
            await client
                .from('dismissed_jobs')
                .delete()
                .eq('profile_id', uid)
                .eq('job_id', jobId);
          }
        }
      } else {
        await ref
            .read(sharedPreferencesProvider)
            .setStringList(CacheKeys.dismissedJobs, current.toList());
      }
    } catch (_) {
      ref.invalidateSelf(); // revert to the source of truth on failure
    }
  }
}

final dismissedControllerProvider =
    AsyncNotifierProvider<DismissedController, Set<String>>(
      DismissedController.new,
    );
