import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cv_repository.dart';
import '../domain/cv_models.dart';

/// Shared base for the CV list sections. Each subclass binds [fetch] to a
/// repository getter; [refresh] re-reads after a mutation.
abstract class _CvListController<T> extends AsyncNotifier<List<T>> {
  CvRepository get repo => ref.read(cvRepositoryProvider);

  Future<List<T>> fetch();

  @override
  Future<List<T>> build() => fetch();

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

class ExperiencesController extends _CvListController<Experience> {
  @override
  Future<List<Experience>> fetch() => repo.experiences();
  Future<void> save(Experience e) async {
    await repo.saveExperience(e);
    await refresh();
  }

  Future<void> remove(String id) async {
    await repo.deleteExperience(id);
    await refresh();
  }
}

class EducationsController extends _CvListController<Education> {
  @override
  Future<List<Education>> fetch() => repo.educations();
  Future<void> save(Education e) async {
    await repo.saveEducation(e);
    await refresh();
  }

  Future<void> remove(String id) async {
    await repo.deleteEducation(id);
    await refresh();
  }
}

class ProjectsController extends _CvListController<Project> {
  @override
  Future<List<Project>> fetch() => repo.projects();
  Future<void> save(Project e) async {
    await repo.saveProject(e);
    await refresh();
  }

  Future<void> remove(String id) async {
    await repo.deleteProject(id);
    await refresh();
  }
}

class CertificationsController extends _CvListController<Certification> {
  @override
  Future<List<Certification>> fetch() => repo.certifications();
  Future<void> save(Certification e) async {
    await repo.saveCertification(e);
    await refresh();
  }

  Future<void> remove(String id) async {
    await repo.deleteCertification(id);
    await refresh();
  }
}

class VolunteerController extends _CvListController<Volunteer> {
  @override
  Future<List<Volunteer>> fetch() => repo.volunteer();
  Future<void> save(Volunteer e) async {
    await repo.saveVolunteer(e);
    await refresh();
  }

  Future<void> remove(String id) async {
    await repo.deleteVolunteer(id);
    await refresh();
  }
}

class AwardsController extends _CvListController<Award> {
  @override
  Future<List<Award>> fetch() => repo.awards();
  Future<void> save(Award e) async {
    await repo.saveAward(e);
    await refresh();
  }

  Future<void> remove(String id) async {
    await repo.deleteAward(id);
    await refresh();
  }
}

class SkillsController extends _CvListController<String> {
  @override
  Future<List<String>> fetch() => repo.skills();
  Future<void> save(List<String> names) async {
    await repo.setSkills(names);
    await refresh();
  }
}

class ResumesController extends _CvListController<Resume> {
  @override
  Future<List<Resume>> fetch() => repo.resumes();
}

final experiencesControllerProvider =
    AsyncNotifierProvider<ExperiencesController, List<Experience>>(
      ExperiencesController.new,
    );
final educationsControllerProvider =
    AsyncNotifierProvider<EducationsController, List<Education>>(
      EducationsController.new,
    );
final projectsControllerProvider =
    AsyncNotifierProvider<ProjectsController, List<Project>>(
      ProjectsController.new,
    );
final certificationsControllerProvider =
    AsyncNotifierProvider<CertificationsController, List<Certification>>(
      CertificationsController.new,
    );
final volunteerControllerProvider =
    AsyncNotifierProvider<VolunteerController, List<Volunteer>>(
      VolunteerController.new,
    );
final awardsControllerProvider =
    AsyncNotifierProvider<AwardsController, List<Award>>(AwardsController.new);
final skillsControllerProvider =
    AsyncNotifierProvider<SkillsController, List<String>>(SkillsController.new);
final resumesControllerProvider =
    AsyncNotifierProvider<ResumesController, List<Resume>>(
      ResumesController.new,
    );

/// Contact info is a single record, not a list.
final contactInfoProvider = FutureProvider<ContactInfo>(
  (ref) => ref.read(cvRepositoryProvider).contactInfo(),
);
