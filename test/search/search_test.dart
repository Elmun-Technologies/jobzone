import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/search/data/search_repository.dart';
import 'package:jobzone/features/search/domain/search_filters.dart';

void main() {
  group('SearchQuery.from', () {
    test('builds Meilisearch filters and sort', () {
      final q = SearchQuery.from(
        const SearchFilters(
          query: 'flutter',
          jobTypes: {'full_time'},
          salaryMin: 1000,
          sort: SearchSort.salaryHigh,
        ),
      );
      expect(q.q, 'flutter');
      expect(q.filters, contains('job_type IN ["full_time"]'));
      expect(q.filters, contains('salary_max >= 1000'));
      expect(q.sort, ['salary_max:desc']);
    });
  });

  group('SearchRepository (offline)', () {
    late ProviderContainer container;
    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('filters by free-text query', () async {
      final repo = container.read(searchRepositoryProvider);
      final res = await repo.search(const SearchFilters(query: 'designer'));
      expect(res, isNotEmpty);
      expect(
        res.every(
          (j) =>
              j.title.toLowerCase().contains('designer') ||
              j.companyName.toLowerCase().contains('designer'),
        ),
        isTrue,
      );
    });

    test('filters by job type', () async {
      final repo = container.read(searchRepositoryProvider);
      final res = await repo.search(
        const SearchFilters(jobTypes: {'internship'}),
      );
      expect(res, isNotEmpty);
      expect(res.every((j) => j.jobType == 'internship'), isTrue);
    });

    test('sorts by highest pay', () async {
      final repo = container.read(searchRepositoryProvider);
      final res = await repo.search(
        const SearchFilters(sort: SearchSort.salaryHigh),
      );
      for (var i = 0; i + 1 < res.length; i++) {
        expect((res[i].salaryMax ?? 0) >= (res[i + 1].salaryMax ?? 0), isTrue);
      }
    });
  });
}
