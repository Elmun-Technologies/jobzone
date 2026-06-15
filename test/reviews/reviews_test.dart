import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/reviews/data/reviews_repository.dart';
import 'package:jobzone/features/reviews/domain/review.dart';

void main() {
  test('CompanyReview.toInsert maps fields and stamps author', () {
    const review = CompanyReview(
      companyId: 'c1',
      rating: 4,
      title: 'Great place',
      pros: 'Good team',
    );
    final map = review.toInsert('author-123');
    expect(map['company_id'], 'c1');
    expect(map['author_id'], 'author-123');
    expect(map['rating'], 4);
    expect(map['title'], 'Great place');
    expect(map['pros'], 'Good team');
  });

  test('offline submit is readable back for that company', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final repo = container.read(reviewsRepositoryProvider);

    expect(await repo.forCompany('acme-co'), isEmpty);

    await repo.submit(
      const CompanyReview(companyId: 'acme-co', rating: 5, title: 'Loved it'),
    );

    final reviews = await repo.forCompany('acme-co');
    expect(reviews.length, 1);
    expect(reviews.first.rating, 5);
    expect(reviews.first.title, 'Loved it');
    // Scoped per company.
    expect(await repo.forCompany('other-co'), isEmpty);
  });
}
