import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/jobs/data/categories_repository.dart';

void main() {
  // No Supabase env in tests → the repository serves its static taxonomy.
  group('CategoriesRepository (offline)', () {
    test('serves white- and blue-collar + foreign-jobs categories', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final cats = await container
          .read(categoriesRepositoryProvider)
          .categories();
      final slugs = cats.map((c) => c.slug).toSet();
      expect(
        slugs,
        containsAll(<String>[
          'engineering',
          'horeca',
          'driver',
          'foreign-jobs',
        ]),
      );
    });

    test('byId resolves a known category and is null otherwise', () {
      expect(CategoriesRepository.byId('driver')?.name, 'Drivers');
      expect(CategoriesRepository.byId('nope'), isNull);
      expect(CategoriesRepository.byId(null), isNull);
    });
  });
}
