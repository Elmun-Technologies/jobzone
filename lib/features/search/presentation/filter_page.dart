import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/enums/enums.dart';
import '../../jobs/presentation/util/job_labels.dart';
import '../application/search_controller.dart';
import '../domain/search_filters.dart';

class FilterPage extends ConsumerStatefulWidget {
  const FilterPage({super.key});

  @override
  ConsumerState<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends ConsumerState<FilterPage> {
  late SearchFilters _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(searchControllerProvider.notifier).filters;
  }

  Set<String> _toggled(Set<String> set, String value) {
    final next = {...set};
    next.contains(value) ? next.remove(value) : next.add(value);
    return next;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final salary = (_draft.salaryMin ?? 0).toDouble();

    return JzScaffold(
      title: l.filterTitle,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _group(
                  l.prefJobTypeTitle,
                  {
                    for (final e in JobType.values)
                      e.wire: jobTypeLabel(context, e.wire) ?? e.wire,
                  },
                  _draft.jobTypes,
                  (w) => setState(
                    () => _draft = _draft.copyWith(
                      jobTypes: _toggled(_draft.jobTypes, w),
                    ),
                  ),
                ),
                _group(
                  l.prefExperienceTitle,
                  {
                    for (final e in ExperienceLevel.values)
                      e.wire: experienceLabel(context, e.wire) ?? e.wire,
                  },
                  _draft.experienceLevels,
                  (w) => setState(
                    () => _draft = _draft.copyWith(
                      experienceLevels: _toggled(_draft.experienceLevels, w),
                    ),
                  ),
                ),
                _group(
                  l.prefWorkingModelTitle,
                  {
                    for (final e in WorkingModel.values)
                      e.wire: workingModelLabel(context, e.wire) ?? e.wire,
                  },
                  _draft.workingModels,
                  (w) => setState(
                    () => _draft = _draft.copyWith(
                      workingModels: _toggled(_draft.workingModels, w),
                    ),
                  ),
                ),
                Text(
                  salary == 0
                      ? l.salaryFrom
                      : '${l.salaryFrom}: \$${salary.toInt()}',
                  style: context.text.titleSmall,
                ),
                Slider(
                  value: salary,
                  max: 5000,
                  divisions: 10,
                  label: '\$${salary.toInt()}',
                  onChanged: (v) => setState(
                    () => _draft = v == 0
                        ? _draft.copyWith(clearSalary: true)
                        : _draft.copyWith(salaryMin: v),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(l.sortBy, style: context.text.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<SearchSort>(
                  segments: [
                    ButtonSegment(
                      value: SearchSort.newest,
                      label: Text(l.sortNewest),
                    ),
                    ButtonSegment(
                      value: SearchSort.salaryHigh,
                      label: Text(l.sortSalaryHigh),
                    ),
                    ButtonSegment(
                      value: SearchSort.salaryLow,
                      label: Text(l.sortSalaryLow),
                    ),
                  ],
                  selected: {_draft.sort},
                  onSelectionChanged: (s) =>
                      setState(() => _draft = _draft.copyWith(sort: s.first)),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(
                        () => _draft = SearchFilters(query: _draft.query),
                      ),
                      child: Text(l.reset),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: JzPrimaryButton(
                      label: l.applyFilters,
                      onPressed: () {
                        ref
                            .read(searchControllerProvider.notifier)
                            .applyFilters(_draft);
                        context.pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(
    String title,
    Map<String, String> options,
    Set<String> selected,
    ValueChanged<String> onToggle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final e in options.entries)
                FilterChip(
                  label: Text(e.value),
                  selected: selected.contains(e.key),
                  onSelected: (_) => onToggle(e.key),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
