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
}
