import 'job.dart';

abstract interface class JobsRepository {
  Future<List<Job>> suggested({int limit});
  Future<List<Job>> recent({int limit});

  /// One page of open jobs for infinite-scroll lists. [offset] is zero-based;
  /// [limit] is the page size. Returns fewer than [limit] items on the last page.
  Future<List<Job>> jobsPage({
    required int offset,
    required int limit,
    bool recentFirst = true,
  });

  Future<Job?> byId(String id);
  Future<List<Job>> byIds(Iterable<String> ids);
  Future<List<Job>> byCompany(String companyId, {int limit});

  /// Open jobs in a single category (matched by the joined category name), read
  /// straight from the feed so a freshly-posted job appears in its category
  /// immediately — no search reindex required.
  Future<List<Job>> byCategory(String categoryName, {int limit});

  /// Open-vacancy counts keyed by category name — backs the "browse by
  /// category" strip. Sourced from the feed for parity with the web app.
  Future<Map<String, int>> categoryCounts();
}
