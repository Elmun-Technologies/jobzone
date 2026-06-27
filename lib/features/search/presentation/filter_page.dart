import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/enums/enums.dart';
import '../../jobs/presentation/util/job_labels.dart';
import '../../preferences/presentation/widgets/preference_step.dart';
import '../application/search_controller.dart';
import '../domain/search_filters.dart';

const _cities = ['Tashkent', 'Samarkand', 'Remote'];
const _jobTitles = <String>[
  'Accountant',
  'Business Development Manager',
  'Content Writer',
  'Data Analyst',
  'Finance Manager',
  'Graphic Designer',
  'Software Engineer',
  'UX/UI Designer',
];

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
    final colors = context.colors;
    // UZS-scaled range (this is a UZS-first market; jobs are in millions of
    // so'm). A USD-scaled 20k–80k range silently excluded every UZS posting.
    const salaryMax = 30000000.0; // 30 mln so'm
    final salary = RangeValues(
      (_draft.salaryMin ?? 0).toDouble().clamp(0, salaryMax),
      (_draft.salaryMax ?? salaryMax).toDouble().clamp(0, salaryMax),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.filterTitle),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  Text(l.locationLabel, style: _sectionStyle(context)),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _draft.city,
                    isExpanded: true,
                    hint: Text(l.searchLocationHint),
                    items: [
                      for (final c in _cities)
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (v) =>
                        setState(() => _draft = _draft.copyWith(city: v)),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(l.salaryLabel, style: _sectionStyle(context)),
                  RangeSlider(
                    values: salary,
                    max: salaryMax,
                    divisions: 6,
                    labels: RangeLabels(
                      '${(salary.start / 1000000).round()} mln',
                      salary.end >= salaryMax
                          ? '${(salaryMax / 1000000).round()} mln+'
                          : '${(salary.end / 1000000).round()} mln',
                    ),
                    onChanged: (v) => setState(
                      () => _draft = _draft.copyWith(
                        salaryMin: v.start,
                        salaryMax: v.end,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final k in const [0, 10, 20, 30])
                        Text(
                          k == 30 ? '30 mln+' : '$k mln',
                          style: context.text.labelSmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _ChipSection(
                    title: l.fieldWorkingModel,
                    options: {
                      for (final e in WorkingModel.values)
                        e.wire: workingModelLabel(context, e.wire) ?? e.wire,
                    },
                    selected: _draft.workingModels,
                    onChanged: (s) => setState(
                      () => _draft = _draft.copyWith(workingModels: s),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _ChipSection(
                    title: l.fieldJobType,
                    options: {
                      for (final e in JobType.values)
                        e.wire: jobTypeLabel(context, e.wire) ?? e.wire,
                    },
                    selected: _draft.jobTypes,
                    onChanged: (s) =>
                        setState(() => _draft = _draft.copyWith(jobTypes: s)),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _ChipSection(
                    title: l.fieldLevel,
                    options: {
                      for (final e in ExperienceLevel.values)
                        e.wire: experienceLabel(context, e.wire) ?? e.wire,
                    },
                    selected: _draft.experienceLevels,
                    onChanged: (s) => setState(
                      () => _draft = _draft.copyWith(experienceLevels: s),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(l.fieldJobTitle, style: _sectionStyle(context)),
                  const SizedBox(height: AppSpacing.sm),
                  OptionCheckList(
                    options: {for (final t in _jobTitles) t: t},
                    selected: _draft.titles,
                    onToggle: (t) => setState(
                      () => _draft = _draft.copyWith(
                        titles: _toggled(_draft.titles, t),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
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
          ],
        ),
      ),
    );
  }

  TextStyle? _sectionStyle(BuildContext context) =>
      context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700);
}

/// A labelled horizontal chip row with a leading "All" chip (clears the set).
class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final Map<String, String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _Chip(
                label: context.l10n.categoryAll,
                selected: selected.isEmpty,
                onTap: () => onChanged(const {}),
              ),
              for (final e in options.entries)
                _Chip(
                  label: e.value,
                  selected: selected.contains(e.key),
                  onTap: () {
                    final next = {...selected};
                    next.contains(e.key) ? next.remove(e.key) : next.add(e.key);
                    onChanged(next);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: context.text.labelLarge?.copyWith(
              color: selected ? colors.onPrimary : colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
