import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/saved_search.dart';

/// Reads/writes the seeker's saved searches. Live via Supabase (owner-scoped by
/// RLS); offline it keeps an in-memory list so the UI is demoable without a
/// backend.
class SavedSearchesRepository {
  SavedSearchesRepository(this._ref);

  final Ref _ref;
  final List<SavedSearch> _offline = [];
  int _seq = 0;

  bool get _live => Env.hasSupabase;
  SupabaseClient get _client => _ref.read(supabaseClientProvider);

  Future<List<SavedSearch>> list() async {
    if (!_live) return _offline.reversed.toList();
    final rows = await _client
        .from('saved_searches')
        .select()
        .order('created_at', ascending: false);
    return rows.map<SavedSearch>((r) => SavedSearch.fromMap(r)).toList();
  }

  Future<void> create({
    required String name,
    String? keywords,
    String? city,
  }) async {
    if (!_live) {
      _offline.add(
        SavedSearch(
          id: 'local-${_seq++}',
          name: name,
          keywords: keywords,
          city: city,
        ),
      );
      return;
    }
    final uid = _client.auth.currentUser?.id;
    await _client.from('saved_searches').insert({
      'profile_id': uid,
      'name': name,
      if (keywords != null && keywords.isNotEmpty) 'keywords': keywords,
      if (city != null && city.isNotEmpty) 'city': city,
    });
  }

  Future<void> delete(String id) async {
    if (!_live) {
      _offline.removeWhere((s) => s.id == id);
      return;
    }
    await _client.from('saved_searches').delete().eq('id', id);
  }
}

final savedSearchesRepositoryProvider = Provider<SavedSearchesRepository>(
  (ref) => SavedSearchesRepository(ref),
);

/// The seeker's saved searches as an [AsyncValue], with add/remove mutations.
class SavedSearchesController extends AsyncNotifier<List<SavedSearch>> {
  @override
  Future<List<SavedSearch>> build() =>
      ref.read(savedSearchesRepositoryProvider).list();

  Future<void> add({
    required String name,
    String? keywords,
    String? city,
  }) async {
    await ref
        .read(savedSearchesRepositoryProvider)
        .create(name: name, keywords: keywords, city: city);
    state = await AsyncValue.guard(
      () => ref.read(savedSearchesRepositoryProvider).list(),
    );
  }

  Future<void> remove(String id) async {
    await ref.read(savedSearchesRepositoryProvider).delete(id);
    state = await AsyncValue.guard(
      () => ref.read(savedSearchesRepositoryProvider).list(),
    );
  }
}

final savedSearchesControllerProvider =
    AsyncNotifierProvider<SavedSearchesController, List<SavedSearch>>(
      SavedSearchesController.new,
    );
