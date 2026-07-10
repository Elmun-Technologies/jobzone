import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/enums/enums.dart';
import '../../../shared/options/option_lists.dart';
import '../../jobs/presentation/util/job_labels.dart';
import '../../preferences/presentation/widgets/preference_step.dart';
import '../application/search_controller.dart';
import '../data/search_repository.dart';
import '../domain/search_filters.dart';

class FilterPage extends ConsumerStatefulWidget {
  const FilterPage({super.key});

  @override
  ConsumerState<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends ConsumerState<FilterPage> {
  late SearchFilters _draft;

  /// Live count of vacancies matching [_draft], shown on the apply button.
  /// Null until the first (debounced) count resolves.
  int? _count;
  Timer? _countTimer;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(searchControllerProvider.notifier).filters;
  }

  @override
  void dispose() {
    _countTimer?.cancel();
    super.dispose();
  }

  // Debounced live result count. Called from build (i.e. after each facet
  // change); the change-guard lets it settle — an unchanged count skips
  // setState, so no further rebuild reschedules the timer.
  void _scheduleCount() {
    _countTimer?.cancel();
    _countTimer = Timer(const Duration(milliseconds: 350), () async {
      final n = await ref.read(searchRepositoryProvider).count(_draft);
      if (mounted && n != _count) setState(() => _count = n);
    });
  }

  Set<String> _toggled(Set<String> set, String value) {
    final next = {...set};
    next.contains(value) ? next.remove(value) : next.add(value);
    return next;
  }

  @override
  Widget build(BuildContext context) {
    _scheduleCount();
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
                    // Localized city labels over stable wire values ("Remote"
                    // was dropped — it's a working model, not a city).
                    items: [
                      for (final c in cityOptions(l).entries)
                        DropdownMenuItem(value: c.key, child: Text(c.value)),
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
                  _ChipSection(
                    title: l.fieldSchedulePattern,
                    options: {
                      for (final e in SchedulePattern.values)
                        e.wire: schedulePatternLabel(context, e.wire) ?? e.wire,
                    },
                    selected: _draft.schedulePatterns,
                    onChanged: (s) => setState(
                      () => _draft = _draft.copyWith(schedulePatterns: s),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _ChipSection(
                    title: l.fieldFormalization,
                    options: {
                      for (final e in Formalization.values)
                        e.wire: formalizationLabel(context, e.wire) ?? e.wire,
                    },
                    selected: _draft.formalizations,
                    onChanged: (s) => setState(
                      () => _draft = _draft.copyWith(formalizations: s),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _ChipSection(
                    title: l.driverLicenseLabel,
                    options: {for (final c in kDriverLicenseCategories) c: c},
                    selected: _draft.driverLicenses,
                    onChanged: (s) => setState(
                      () => _draft = _draft.copyWith(driverLicenses: s),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.fieldNightShift,
                          style: _sectionStyle(context),
                        ),
                      ),
                      Switch(
                        value: _draft.nightShift,
                        onChanged: (v) => setState(
                          () => _draft = _draft.copyWith(nightShift: v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(l.postedWithinLabel, style: _sectionStyle(context)),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _Chip(
                          label: l.postedAny,
                          selected: _draft.postedWithin == null,
                          onTap: () => setState(
                            () => _draft = _draft.copyWith(
                              clearPostedWithin: true,
                            ),
                          ),
                        ),
                        for (final e in [
                          (1, l.posted1d),
                          (3, l.posted3d),
                          (7, l.posted7d),
                          (30, l.posted30d),
                        ])
                          _Chip(
                            label: e.$2,
                            selected: _draft.postedWithin == e.$1,
                            onTap: () => setState(
                              () =>
                                  _draft = _draft.copyWith(postedWithin: e.$1),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _ChipSection(
                    title: l.salaryPeriodLabel,
                    options: {
                      'hour': l.periodHour,
                      'day': l.periodDay,
                      'week': l.periodWeek,
                      'month': l.periodMonth,
                      'year': l.periodYear,
                    },
                    selected: _draft.salaryPeriods,
                    onChanged: (s) => setState(
                      () => _draft = _draft.copyWith(salaryPeriods: s),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(l.fieldJobTitle, style: _sectionStyle(context)),
                  const SizedBox(height: AppSpacing.sm),
                  OptionCheckList(
                    options: jobTitleOptions(l),
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
                      label: _count == null
                          ? l.applyFilters
                          : l.filterShowCount(_count!),
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
