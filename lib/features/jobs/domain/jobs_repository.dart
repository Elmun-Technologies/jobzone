import 'job.dart';

abstract interface class JobsRepository {
  Future<List<Job>> suggested({int limit});
  Future<List<Job>> recent({int limit});
  Future<Job?> byId(String id);
  Future<List<Job>> byIds(Iterable<String> ids);
  Future<List<Job>> byCompany(String companyId, {int limit});
}
