import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../data/applicants_repository.dart';
import 'widgets/applicant_card.dart';
import 'widgets/applicant_sort_bar.dart';

/// Applicants for a single job posting.
class JobApplicantsPage extends ConsumerStatefulWidget {
  const JobApplicantsPage({super.key, required this.jobId, this.jobTitle});

  final String jobId;
  final String? jobTitle;

  @override
  ConsumerState<JobApplicantsPage> createState() => _JobApplicantsPageState();
}

class _JobApplicantsPageState extends ConsumerState<JobApplicantsPage> {
  ApplicantSort _sort = ApplicantSort.newest;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final async = ref.watch(jobApplicantsProvider(widget.jobId));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: widget.jobTitle ?? l.navApplicants),
            ),
            Expanded(
              child: async.when(
                loading: () => const JzLoader(),
                error: (_, _) => Center(child: Text(l.errUnknown)),
                data: (applicants) {
                  if (applicants.isEmpty) {
                    return JzEmptyState(
                      icon: Icons.people_outline_rounded,
                      title: l.noApplicantsTitle,
                      message: l.noApplicantsBody,
                    );
                  }
                  final sorted = sortApplicants(applicants, _sort);
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        child: ApplicantSortBar(
                          sort: _sort,
                          onSort: (s) => setState(() => _sort = s),
                          onMap: () => context.push(
                            Routes.employerJobApplicantsMap(widget.jobId),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.lg,
                          ),
                          itemCount: sorted.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, i) => ApplicantCard(
                            applicant: sorted[i],
                            onTap: () => context.push(
                              Routes.employerApplicant(sorted[i].id),
                              extra: sorted[i],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
