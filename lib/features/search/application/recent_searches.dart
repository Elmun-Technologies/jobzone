import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_cache.dart';

/// Recently used search queries, persisted locally (most-recent first, max 8).
class RecentSearches extends Notifier<List<String>> {
  @override
  List<String> build() =>
      ref
          .read(sharedPreferencesProvider)
          .getStringList(CacheKeys.recentSearches) ??
      const [];

  void add(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    _save([q, ...state.where((e) => e != q)].take(8).toList());
  }

  void remove(String query) => _save(state.where((e) => e != query).toList());

  void _save(List<String> next) {
    state = next;
    ref
        .read(sharedPreferencesProvider)
        .setStringList(CacheKeys.recentSearches, next);
  }
}

final recentSearchesProvider = NotifierProvider<RecentSearches, List<String>>(
  RecentSearches.new,
);
