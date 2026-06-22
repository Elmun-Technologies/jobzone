import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/applications/application/applications_controller.dart';
import 'package:jobzone/features/jobs/data/mock_jobs.dart';
import 'package:jobzone/shared/enums/enums.dart';

void main() {
  test('apply adds a submitted application (offline)', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final before = await container.read(applicationsControllerProvider.future);
    await container
        .read(applicationsControllerProvider.notifier)
        .apply(job: mockJobs.first, coverLetter: 'Hello');
    final after = container.read(applicationsControllerProvider).value ?? [];

    expect(after.length, before.length + 1);
    // Most-recent first.
    expect(after.first.job.id, mockJobs.first.id);
    expect(after.first.status, ApplicationStatus.submitted);
    expect(after.first.coverLetter, 'Hello');
  });

  test('apply persists screening answers (offline)', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(applicationsControllerProvider.notifier)
        .apply(
          job: mockJobs.first,
          answers: const {'q-exp': '5', 'q-remote': true},
        );
    final apps = container.read(applicationsControllerProvider).value ?? [];
    expect(apps.first.answers['q-exp'], '5');
    expect(apps.first.answers['q-remote'], true);
  });
}
