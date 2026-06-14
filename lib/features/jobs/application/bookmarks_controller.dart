import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/storage/local_cache.dart';
import '../../../core/supabase/supabase_providers.dart';

/// Holds the set of bookmarked job ids. Backed by the `bookmarks` table when
/// Supabase is configured, otherwise by SharedPreferences (offline mode).
class BookmarksController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    if (Env.hasSupabase) {
      final client = ref.read(supabaseClientProvider);
      final uid = client.auth.currentUser?.id;
      if (uid == null) return <String>{};
      final rows = await client
          .from('bookmarks')
          .select('job_id')
          .eq('profile_id', uid);
      return rows.map<String>((r) => r['job_id'] as String).toSet();
    }
    final prefs = ref.read(sharedPreferencesProvider);
    return (prefs.getStringList(CacheKeys.bookmarks) ?? const <String>[])
        .toSet();
  }

  bool isBookmarked(String jobId) => state.value?.contains(jobId) ?? false;

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
            await client.from('bookmarks').insert({
              'profile_id': uid,
              'job_id': jobId,
            });
          } else {
            await client
                .from('bookmarks')
                .delete()
                .eq('profile_id', uid)
                .eq('job_id', jobId);
          }
        }
      } else {
        await ref
            .read(sharedPreferencesProvider)
            .setStringList(CacheKeys.bookmarks, current.toList());
      }
    } catch (_) {
      ref.invalidateSelf(); // revert to the source of truth on failure
    }
  }
}

final bookmarksControllerProvider =
    AsyncNotifierProvider<BookmarksController, Set<String>>(
      BookmarksController.new,
    );
