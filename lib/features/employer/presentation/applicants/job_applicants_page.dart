import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/enums/enums.dart';
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
  ApplicationStatus? _statusFilter;

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
                error: (_, _) => JzErrorState(
                  title: l.errorTitle,
                  message: l.errUnknown,
                  retryLabel: l.retry,
                  onRetry: () =>
                      ref.invalidate(jobApplicantsProvider(widget.jobId)),
                ),
                data: (applicants) {
                  if (applicants.isEmpty) {
                    return JzEmptyState(
                      icon: Icons.people_outline_rounded,
                      title: l.noApplicantsTitle,
                      message: l.noApplicantsBody,
                    );
                  }

                  final counts = <ApplicationStatus, int>{};
                  for (final a in applicants) {
                    counts[a.status] = (counts[a.status] ?? 0) + 1;
                  }

                  final sorted = sortApplicants(applicants, _sort);
                  final filtered = _statusFilter == null
                      ? sorted
                      : sorted.where((a) => a.status == _statusFilter).toList();

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
                          statusCounts: counts,
                          statusFilter: _statusFilter,
                          onStatusFilter: (s) =>
                              setState(() => _statusFilter = s),
                        ),
                      ),
                      Expanded(
                        child: filtered.isEmpty
                            ? JzEmptyState(
                                icon: Icons.filter_list_rounded,
                                title: l.noApplicantsForStatus,
                                message: '',
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.lg,
                                  0,
                                  AppSpacing.lg,
                                  AppSpacing.lg,
                                ),
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: AppSpacing.md),
                                itemBuilder: (context, i) => ApplicantCard(
                                  applicant: filtered[i],
                                  onTap: () => context.push(
                                    Routes.employerApplicant(filtered[i].id),
                                    extra: filtered[i],
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
