import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards `lib/shared/providers/account_scope.dart`.
///
/// Every long-lived (non-`autoDispose`) provider resolves `auth.currentUser`
/// once, when it is first built, and then caches for the life of the process.
/// If one holding per-account data isn't reset when the identity changes, the
/// next account to sign in on the device inherits the previous one's data.
///
/// That's easy to reintroduce: adding a provider is a one-line change in a
/// feature folder, far away from the reset list. So this test enumerates every
/// long-lived provider in `lib/features` and requires each to be either listed
/// in the reset, or named here as deliberately global.
void main() {
  /// Providers whose data does not belong to one account: public catalogs
  /// keyed by id, auth machinery, and transient UI state.
  const global = {
    'authControllerProvider', // the sign-in call itself
    'pushDeepLinksProvider', // FCM tap stream, not user data
    'jobCategoriesProvider',
    'jobByIdProvider',
    'recentJobsProvider',
    'suggestedJobsProvider',
    'companyJobsProvider',
    'paginatedJobsProvider',
    'categoryJobsProvider',
    'categoryCountsProvider',
    'collectionJobsProvider',
    'companyByIdProvider',
    'companyPeopleProvider',
    'companyGalleryProvider',
    'companyReviewsProvider',
    'promotionProductsProvider',
    'searchControllerProvider', // the query being typed
    // Device-local search history in SharedPreferences, like a browser's.
    // Invalidating wouldn't clear it anyway — it rebuilds from the same prefs.
    'recentSearchesProvider',
  };

  test('every long-lived feature provider is account-scoped or listed global', () {
    final reset = File(
      'lib/shared/providers/account_scope.dart',
    ).readAsStringSync();
    final listed = RegExp(
      r'ref\.invalidate\((\w+)\)',
    ).allMatches(reset).map((m) => m.group(1)!).toSet();

    final declaration = RegExp(
      r'^final\s+(\w+)\s*=\s*'
      r'(AsyncNotifierProvider|NotifierProvider|FutureProvider|StreamProvider)'
      r'(\.autoDispose)?',
      multiLine: true,
    );

    final unaccounted = <String, String>{};
    for (final entity in Directory('lib/features').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      for (final m in declaration.allMatches(source)) {
        if (m.group(3) != null) continue; // autoDispose drops its own cache
        final name = m.group(1)!;
        if (listed.contains(name) || global.contains(name)) continue;
        unaccounted[name] = entity.path;
      }
    }

    expect(
      unaccounted,
      isEmpty,
      reason:
          'These providers cache for the life of the process but are neither '
          'reset on account switch nor declared global. Add each to '
          'invalidateAccountScope() if it holds per-account data, or to the '
          '`global` set in this test if it does not:\n'
          '${unaccounted.entries.map((e) => '  ${e.key} (${e.value})').join('\n')}',
    );
  });
}
