import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/search/data/search_repository.dart';
import 'package:jobzone/features/search/domain/job_collection.dart';
import 'package:jobzone/features/search/domain/search_filters.dart';

/// Asserts a [JobCollection]'s preset only returns jobs matching its facet.
bool _matches(JobCollection c, dynamic j) => switch (c) {
  JobCollection.freshers => j.experienceLevel == 'entry',
  JobCollection.remote => j.workingModel == 'remote',
  JobCollection.partTime => j.jobType == 'part_time',
  JobCollection.fullTime => j.jobType == 'full_time',
  JobCollection.rotational => j.jobType == 'rotational',
  JobCollection.women => j.womenFriendly == true,
  JobCollection.nightShift => j.nightShift == true,
  JobCollection.disability => j.disabilityFriendly == true,
};

void main() {
  group('SearchQuery.from — quick-find facets', () {
    test('emits women_friendly and night_shift filters', () {
      final women = SearchQuery.from(const SearchFilters(womenFriendly: true));
      expect(women.filters, contains('women_friendly = true'));

      final night = SearchQuery.from(const SearchFilters(nightShift: true));
      expect(night.filters, contains('night_shift = true'));
    });

    test('omits the facets when off', () {
      final q = SearchQuery.from(const SearchFilters());
      expect(q.filters, isNot(contains('women_friendly = true')));
      expect(q.filters, isNot(contains('night_shift = true')));
    });
  });

  group('JobCollection', () {
    test('fromKey round-trips every collection', () {
      for (final c in JobCollection.values) {
        expect(JobCollection.fromKey(c.key), c);
      }
      expect(JobCollection.fromKey('nope'), isNull);
      expect(JobCollection.fromKey(null), isNull);
    });
  });

  group('Collection presets (offline)', () {
    late ProviderContainer container;
    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    for (final c in JobCollection.values) {
      test('${c.key} returns only matching jobs', () async {
        final repo = container.read(searchRepositoryProvider);
        final res = await repo.search(c.preset);
        expect(res, isNotEmpty, reason: 'expected demo data for ${c.key}');
        expect(res.every((j) => _matches(c, j)), isTrue);
      });
    }
  });
}
