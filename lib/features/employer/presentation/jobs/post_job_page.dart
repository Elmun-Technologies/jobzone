import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/markdown_edit.dart';
import '../../../../core/utils/uzbekistan_regions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../app/router/routes.dart';
import '../../../../shared/enums/enums.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../../jobs/data/categories_repository.dart';
import '../../../jobs/domain/job.dart';
import '../../../jobs/domain/job_language.dart';
import '../../../jobs/domain/screening_question.dart';
import '../../../jobs/presentation/category_label.dart';
import '../../../jobs/presentation/job_details_page.dart';
import '../../../monetization/presentation/promote_sheet.dart';
import '../../data/ai_content_repository.dart';
import '../../data/employer_jobs_repository.dart';
import 'widgets/job_location_picker.dart';

/// Create or edit a job posting. Pass [job] (via the edit route's `extra`) to
/// prefill the form for editing; omit it to create a new posting.
class PostJobPage extends ConsumerStatefulWidget {
  const PostJobPage({super.key, this.job, this.duplicate = false});

  final Job? job;

  /// When true, [job] only prefills the form and a NEW posting is created
  /// (used by "duplicate / use as template").
  final bool duplicate;

  @override
  ConsumerState<PostJobPage> createState() => _PostJobPageState();
}

class _PostJobPageState extends ConsumerState<PostJobPage> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.job?.title);
  late final _city = TextEditingController(text: widget.job?.city);
  late final _min = TextEditingController(
    text: widget.job?.salaryMin?.toStringAsFixed(0),
  );
  late final _max = TextEditingController(
    text: widget.job?.salaryMax?.toStringAsFixed(0),
  );
  late final _skills = TextEditingController(
    text: widget.job?.skills.join(', '),
  );
  late final _description = TextEditingController(
    text: widget.job?.description,
  );
  late final _requirements = TextEditingController(
    text: widget.job?.requirements,
  );
  late String? _type = widget.job?.jobType;
  late String? _level = widget.job?.experienceLevel;
  late String? _model = widget.job?.workingModel;
  late String? _payType = widget.job?.salaryPeriod;
  late String? _payoutFreq = widget.job?.payoutFrequency;
  late String _currency = widget.job?.currency ?? 'UZS';
  late String? _categoryId = widget.job?.categoryId;
  late String? _schedule = widget.job?.schedulePattern;
  late String? _formalization = widget.job?.formalization;
  late bool _nightShift = widget.job?.nightShift ?? false;
  late bool _womenFriendly = widget.job?.womenFriendly ?? false;
  late bool _salaryGross = widget.job?.salaryGross ?? true;
  late final Set<String> _licenses = {...?widget.job?.driverLicenses};
  late List<JobLanguage> _languages = [...?widget.job?.languages];
  late bool _requireCoverLetter = widget.job?.requireCoverLetter ?? false;
  late bool _disabilityFriendly = widget.job?.disabilityFriendly ?? false;
  late bool _allowIncompleteResume = widget.job?.allowIncompleteResume ?? false;
  late bool _showPhone = widget.job?.showPhoneOnListing ?? false;
  late final _contactPhone = TextEditingController(
    text: widget.job?.contactPhone,
  );
  late String? _region = widget.job?.region;
  late String? _district = widget.job?.district;
  late String _preferredGender = widget.job?.preferredGender ?? 'any';
  late String? _startAvailability = widget.job?.startAvailability;
  late String _salaryDisplay = widget.job?.salaryDisplay ?? 'exact';
  late final _ageMin = TextEditingController(
    text: widget.job?.ageMin?.toString() ?? '18',
  );
  late final _ageMax = TextEditingController(
    text: widget.job?.ageMax?.toString(),
  );
  late bool _scheduleOn = widget.job?.publishAt != null;
  late DateTime? _publishAt = widget.job?.publishAt;
  late final _hours = TextEditingController(
    text: widget.job?.hoursPerDay?.toString(),
  );
  late final _responsibilities = TextEditingController(
    text: widget.job?.responsibilities,
  );
  late final _benefits = TextEditingController(text: widget.job?.benefits);
  late final _address = TextEditingController(text: widget.job?.addressText);
  late double? _lat = widget.job?.lat;
  late double? _lng = widget.job?.lng;
  late List<ScreeningQuestion> _questions = [
    ...?widget.job?.screeningQuestions,
  ];
  late String _educationRequired = widget.job?.educationRequired ?? 'none';
  late final _workHours = TextEditingController(text: widget.job?.workHours);
  bool _saving = false;
  bool _generating = false;

  bool get _isEdit => widget.job != null && !widget.duplicate;

  @override
  void dispose() {
    _title.dispose();
    _city.dispose();
    _min.dispose();
    _max.dispose();
    _skills.dispose();
    _description.dispose();
    _requirements.dispose();
    _hours.dispose();
    _responsibilities.dispose();
    _benefits.dispose();
    _address.dispose();
    _contactPhone.dispose();
    _ageMin.dispose();
    _ageMax.dispose();
    _workHours.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => JobLocationPicker(
          initial: _lat != null && _lng != null ? LatLng(_lat!, _lng!) : null,
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        _lat = picked.latitude;
        _lng = picked.longitude;
      });
    }
  }

  Future<void> _pickPublishAt() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _publishAt ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_publishAt ?? now),
    );
    if (!mounted) return;
    setState(() {
      _publishAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 9,
        time?.minute ?? 0,
      );
    });
  }

  String _fmtPublishAt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}'
      '.${d.year} ${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';

  Future<void> _generate() async {
    if (_title.text.trim().isEmpty) {
      showInfoSnack(context, context.l10n.aiNeedTitle);
      return;
    }
    setState(() => _generating = true);
    try {
      final skills = _skills.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      // Resolve the category id to its human label so the prompt reads cleanly.
      final cats =
          ref.read(jobCategoriesProvider).value ?? const <JobCategory>[];
      final named = cats.where((c) => c.id == _categoryId).map((c) => c.name);
      final categoryName = named.isEmpty ? null : named.first;
      final locale = Localizations.localeOf(context).languageCode;
      final d = await ref
          .read(aiContentRepositoryProvider)
          .draftJob(
            title: _title.text.trim(),
            category: categoryName,
            jobType: _type,
            skills: skills,
            locale: locale,
          );
      if (!mounted) return;
      setState(() {
        _description.text = d.description;
        _responsibilities.text = d.responsibilities;
        _requirements.text = d.requirements;
        _benefits.text = d.benefits;
      });
    } catch (e) {
      if (mounted) showErrorSnack(context, localizedError(context, e));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _preview() {
    final skills = _skills.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final tempJob = Job(
      id: widget.job?.id ?? 'preview',
      title: _title.text.trim().isEmpty ? '—' : _title.text.trim(),
      companyId: widget.job?.companyId ?? 'preview',
      companyName: widget.job?.companyName ?? '—',
      companyLogoUrl: widget.job?.companyLogoUrl,
      jobType: _type,
      experienceLevel: _level,
      workingModel: _model,
      salaryMin: _salaryDisplay == 'exact' ? num.tryParse(_min.text) : null,
      salaryMax: _salaryDisplay == 'exact' ? num.tryParse(_max.text) : null,
      salaryDisplay: _salaryDisplay,
      currency: _currency,
      salaryPeriod: _payType,
      payoutFrequency: _payoutFreq,
      salaryGross: _salaryGross,
      ageMin: int.tryParse(_ageMin.text),
      ageMax: int.tryParse(_ageMax.text),
      preferredGender: _preferredGender,
      startAvailability: _startAvailability,
      schedulePattern: _schedule,
      hoursPerDay: num.tryParse(_hours.text),
      nightShift: _nightShift,
      formalization: _formalization,
      womenFriendly: _womenFriendly,
      disabilityFriendly: _disabilityFriendly,
      driverLicenses: _licenses.toList(),
      languages: _languages,
      requireCoverLetter: _requireCoverLetter,
      allowIncompleteResume: _allowIncompleteResume,
      showPhoneOnListing: _showPhone,
      contactPhone: _contactPhone.text.trim(),
      region: _region,
      district: _district,
      city: _district ?? _city.text.trim(),
      lat: _lat,
      lng: _lng,
      addressText: _address.text.trim(),
      categoryId: _categoryId,
      skills: skills,
      description: _description.text.trim(),
      responsibilities: _responsibilities.text.trim(),
      requirements: _requirements.text.trim(),
      benefits: _benefits.text.trim(),
      screeningQuestions: _questions,
      status: 'open',
      educationRequired: _educationRequired,
      workHours: _workHours.text.trim().isEmpty ? null : _workHours.text.trim(),
    );
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => JobPreviewPage(job: tempJob)));
  }

  Future<void> _submit(String status) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(employerJobsRepositoryProvider);
    final skills = _skills.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    // Scheduled publish: a future publish_at keeps the job a draft until then.
    final scheduled =
        _scheduleOn &&
        _publishAt != null &&
        _publishAt!.isAfter(DateTime.now());
    final effectiveStatus = status == 'open' && scheduled ? 'draft' : status;
    final publishAt = scheduled ? _publishAt : null;
    try {
      Job? created;
      if (_isEdit) {
        await repo.updateJob(
          widget.job!.copyWith(
            title: _title.text.trim(),
            jobType: _type,
            experienceLevel: _level,
            workingModel: _model,
            salaryMin: _salaryDisplay == 'exact'
                ? num.tryParse(_min.text)
                : null,
            salaryMax: _salaryDisplay == 'exact'
                ? num.tryParse(_max.text)
                : null,
            salaryDisplay: _salaryDisplay,
            ageMin: int.tryParse(_ageMin.text),
            ageMax: int.tryParse(_ageMax.text),
            preferredGender: _preferredGender,
            startAvailability: _startAvailability,
            salaryPeriod: _payType,
            payoutFrequency: _payoutFreq,
            schedulePattern: _schedule,
            hoursPerDay: num.tryParse(_hours.text),
            nightShift: _nightShift,
            formalization: _formalization,
            womenFriendly: _womenFriendly,
            driverLicenses: _licenses.toList(),
            languages: _languages,
            salaryGross: _salaryGross,
            requireCoverLetter: _requireCoverLetter,
            disabilityFriendly: _disabilityFriendly,
            allowIncompleteResume: _allowIncompleteResume,
            showPhoneOnListing: _showPhone,
            contactPhone: _contactPhone.text.trim(),
            currency: _currency,
            categoryId: _categoryId,
            lat: _lat,
            lng: _lng,
            addressText: _address.text.trim(),
            city: _district ?? _city.text.trim(),
            region: _region,
            district: _district,
            skills: skills,
            description: _description.text.trim(),
            responsibilities: _responsibilities.text.trim(),
            requirements: _requirements.text.trim(),
            benefits: _benefits.text.trim(),
            screeningQuestions: _questions
                .where((q) => q.label.trim().isNotEmpty)
                .toList(),
            status: effectiveStatus,
            publishAt: publishAt,
            educationRequired: _educationRequired,
            workHours: _workHours.text.trim().isEmpty
                ? null
                : _workHours.text.trim(),
          ),
        );
      } else {
        created = await repo.createJob(
          title: _title.text.trim(),
          jobType: _type,
          experienceLevel: _level,
          workingModel: _model,
          salaryMin: _salaryDisplay == 'exact' ? num.tryParse(_min.text) : null,
          salaryMax: _salaryDisplay == 'exact' ? num.tryParse(_max.text) : null,
          salaryPeriod: _payType,
          payoutFrequency: _payoutFreq,
          salaryDisplay: _salaryDisplay,
          ageMin: int.tryParse(_ageMin.text),
          ageMax: int.tryParse(_ageMax.text),
          preferredGender: _preferredGender,
          startAvailability: _startAvailability,
          schedulePattern: _schedule,
          hoursPerDay: num.tryParse(_hours.text),
          nightShift: _nightShift,
          formalization: _formalization,
          womenFriendly: _womenFriendly,
          driverLicenses: _licenses.toList(),
          languages: _languages,
          salaryGross: _salaryGross,
          requireCoverLetter: _requireCoverLetter,
          disabilityFriendly: _disabilityFriendly,
          allowIncompleteResume: _allowIncompleteResume,
          showPhoneOnListing: _showPhone,
          contactPhone: _contactPhone.text.trim(),
          currency: _currency,
          categoryId: _categoryId,
          lat: _lat,
          lng: _lng,
          addressText: _address.text.trim(),
          city: _district ?? _city.text.trim(),
          region: _region,
          district: _district,
          skills: skills,
          description: _description.text.trim(),
          responsibilities: _responsibilities.text.trim(),
          requirements: _requirements.text.trim(),
          benefits: _benefits.text.trim(),
          screeningQuestions: _questions
              .where((q) => q.label.trim().isNotEmpty)
              .toList(),
          status: effectiveStatus,
          publishAt: publishAt,
          educationRequired: _educationRequired,
          workHours: _workHours.text.trim().isEmpty
              ? null
              : _workHours.text.trim(),
        );
      }
      ref.invalidate(myJobsProvider);
      if (!mounted) return;
      if (scheduled) {
        showInfoSnack(context, context.l10n.jobScheduledToast);
      } else if (created != null && effectiveStatus == 'open') {
        // Newly published job → offer the tariff/promote sheet before leaving.
        await showPromoteSheet(context, jobId: created.id);
      } else {
        showInfoSnack(context, context.l10n.jobSavedToast);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, localizedError(context, e));
      // No company yet → send them straight to create one so they can
      // publish next; without this the user hits the same wall on retry.
      if (e is NoCompanyError) context.push(Routes.employerOnboard);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cats =
        ref.watch(jobCategoriesProvider).value ?? const <JobCategory>[];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(
                title: _isEdit ? l.editJobTitle : l.postJobCta,
                actions: [
                  TextButton(onPressed: _preview, child: Text(l.previewJob)),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  children: [
                    // Title + category always visible at the top
                    JzTextField(
                      label: l.fieldJobTitle,
                      controller: _title,
                      validator: (v) =>
                          Validators.isNotBlank(v) ? null : l.valRequired,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Dropdown(
                      key: ValueKey('cat-${_categoryId ?? ''}-${cats.length}'),
                      label: l.jobCategory,
                      value: cats.any((c) => c.id == _categoryId)
                          ? _categoryId
                          : null,
                      items: {
                        for (final c in cats)
                          c.id: localizedCategory(l, slug: c.slug),
                      },
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── 1. Bandlik (Employment) ──────────────────────────────
                    _FormSection(
                      title: l.sectionEmployment,
                      initiallyExpanded: true,
                      children: [
                        _Dropdown(
                          label: l.fieldJobType,
                          value: _type,
                          items: {
                            JobType.fullTime.wire: l.jobTypeFullTime,
                            JobType.partTime.wire: l.jobTypePartTime,
                            JobType.contract.wire: l.jobTypeContract,
                            JobType.internship.wire: l.jobTypeInternship,
                            JobType.temporary.wire: l.jobTypeTemporary,
                            JobType.rotational.wire: l.jobTypeRotational,
                          },
                          onChanged: (v) => setState(() => _type = v),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _Dropdown(
                          label: l.fieldExperience,
                          value: _level,
                          items: {
                            ExperienceLevel.entry.wire: l.expEntry,
                            ExperienceLevel.mid.wire: l.expMid,
                            ExperienceLevel.senior.wire: l.expSenior,
                            ExperienceLevel.lead.wire: l.expLead,
                          },
                          onChanged: (v) => setState(() => _level = v),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _Dropdown(
                          label: l.fieldWorkingModel,
                          value: _model,
                          items: {
                            WorkingModel.onsite.wire: l.wmOnsite,
                            WorkingModel.remote.wire: l.wmRemote,
                            WorkingModel.hybrid.wire: l.wmHybrid,
                          },
                          onChanged: (v) => setState(() => _model = v),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _Dropdown(
                          label: l.fieldFormalization,
                          value: _formalization,
                          items: {
                            Formalization.employmentContract.wire:
                                l.formEmploymentContract,
                            Formalization.gph.wire: l.formGph,
                            Formalization.selfEmployed.wire: l.formSelfEmployed,
                            Formalization.none.wire: l.formNone,
                          },
                          onChanged: (v) => setState(() => _formalization = v),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _Dropdown(
                          label: l.fieldSchedulePattern,
                          value: _schedule,
                          items: {
                            SchedulePattern.fiveTwo.wire: '5/2',
                            SchedulePattern.sixOne.wire: '6/1',
                            SchedulePattern.fourFour.wire: '4/4',
                            SchedulePattern.twoTwo.wire: '2/2',
                            SchedulePattern.custom.wire: l.schedCustom,
                          },
                          onChanged: (v) => setState(() => _schedule = v),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        JzTextField(
                          label: l.fieldWorkHours,
                          controller: _workHours,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        JzTextField(
                          label: l.fieldHoursPerDay,
                          controller: _hours,
                          keyboardType: TextInputType.number,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l.fieldNightShift),
                          value: _nightShift,
                          onChanged: (v) => setState(() => _nightShift = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l.fieldWomenFriendly),
                          subtitle: Text(l.fieldWomenFriendlyHint),
                          value: _womenFriendly,
                          onChanged: (v) => setState(() => _womenFriendly = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l.fieldDisabilityFriendly),
                          subtitle: Text(l.fieldDisabilityFriendlyHint),
                          value: _disabilityFriendly,
                          onChanged: (v) =>
                              setState(() => _disabilityFriendly = v),
                        ),
                      ],
                    ),

                    // ── 2. Nomzodlarga talablar (Candidate requirements) ─────
                    _FormSection(
                      title: l.candidateRequirementsSection,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: JzTextField(
                                label: l.fieldAgeMin,
                                controller: _ageMin,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: JzTextField(
                                label: l.fieldAgeMax,
                                controller: _ageMax,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l.fieldPreferredGender,
                          style: context.text.labelLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: [
                            for (final g in ['any', 'male', 'female'])
                              ChoiceChip(
                                label: Text(switch (g) {
                                  'male' => l.preferGenderMale,
                                  'female' => l.preferGenderFemale,
                                  _ => l.preferGenderAny,
                                }),
                                selected: _preferredGender == g,
                                onSelected: (_) =>
                                    setState(() => _preferredGender = g),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l.fieldStartAvailability,
                          style: context.text.labelLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final s in [
                              'immediate',
                              'one_week',
                              'two_weeks',
                              'one_month',
                            ])
                              ChoiceChip(
                                label: Text(switch (s) {
                                  'one_week' => l.startOneWeek,
                                  'two_weeks' => l.startTwoWeeks,
                                  'one_month' => l.startOneMonth,
                                  _ => l.startImmediate,
                                }),
                                selected: _startAvailability == s,
                                onSelected: (v) => setState(
                                  () => _startAvailability = v ? s : null,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l.fieldEducationRequired,
                          style: context.text.labelLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final e in [
                              'none',
                              'secondary',
                              'specialized_secondary',
                              'higher',
                            ])
                              ChoiceChip(
                                label: Text(switch (e) {
                                  'secondary' => l.eduSecondary,
                                  'specialized_secondary' =>
                                    l.eduSpecializedSecondary,
                                  'higher' => l.eduHigher,
                                  _ => l.eduNone,
                                }),
                                selected: _educationRequired == e,
                                onSelected: (_) =>
                                    setState(() => _educationRequired = e),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l.driverLicenseLabel,
                          style: context.text.labelLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: [
                            for (final c in kDriverLicenseCategories)
                              FilterChip(
                                label: Text(c),
                                selected: _licenses.contains(c),
                                onSelected: (v) => setState(
                                  () => v
                                      ? _licenses.add(c)
                                      : _licenses.remove(c),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _LanguagesEditor(
                          languages: _languages,
                          onChanged: (v) => setState(() => _languages = v),
                        ),
                      ],
                    ),

                    // ── 3. Maosh (Salary) ────────────────────────────────────
                    _FormSection(
                      title: l.sectionSalary,
                      children: [
                        _Dropdown(
                          label: l.fieldSalaryDisplay,
                          value: _salaryDisplay,
                          items: {
                            'exact': l.salaryDisplayExact,
                            'negotiable': l.salaryDisplayNegotiable,
                            'hidden': l.salaryDisplayHidden,
                          },
                          onChanged: (v) =>
                              setState(() => _salaryDisplay = v ?? 'exact'),
                        ),
                        if (_salaryDisplay == 'exact') ...[
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: JzTextField(
                                  label: l.fieldSalaryMin,
                                  controller: _min,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (!Validators.isNotBlank(v)) {
                                      return l.valSalaryRequired;
                                    }
                                    return num.tryParse(v!.trim()) == null
                                        ? l.valSalaryRequired
                                        : null;
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: JzTextField(
                                  label: l.fieldSalaryMax,
                                  controller: _max,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (!Validators.isNotBlank(v)) return null;
                                    return num.tryParse(v!.trim()) == null
                                        ? l.valSalaryRequired
                                        : null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        _Dropdown(
                          label: l.currencyLabel,
                          value: _currency,
                          items: {'UZS': l.currencyUzs, 'USD': l.currencyUsd},
                          onChanged: (v) =>
                              setState(() => _currency = v ?? 'UZS'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(l.payBasisLabel, style: context.text.labelLarge),
                        const SizedBox(height: AppSpacing.sm),
                        SegmentedButton<bool>(
                          segments: [
                            ButtonSegment(
                              value: true,
                              label: Text(l.salaryGross),
                            ),
                            ButtonSegment(
                              value: false,
                              label: Text(l.salaryNet),
                            ),
                          ],
                          selected: {_salaryGross},
                          showSelectedIcon: false,
                          onSelectionChanged: (s) =>
                              setState(() => _salaryGross = s.first),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _Dropdown(
                          label: l.payTypeLabel,
                          value: _payType,
                          items: {
                            'month': l.payMonth,
                            'hour': l.payHour,
                            'day': l.payDay,
                            'week': l.payWeek,
                            'shift': l.payShift,
                            'task': l.payTask,
                          },
                          onChanged: (v) => setState(() => _payType = v),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _Dropdown(
                          label: l.payoutFreqLabel,
                          value: _payoutFreq,
                          items: {
                            'monthly': l.payoutMonthly,
                            'biweekly': l.payoutBiweekly,
                            'weekly': l.payoutWeekly,
                            'daily': l.payoutDaily,
                          },
                          onChanged: (v) => setState(() => _payoutFreq = v),
                        ),
                      ],
                    ),

                    // ── 4. Joylashuv (Location) ──────────────────────────────
                    _FormSection(
                      title: l.sectionLocation,
                      children: [
                        _Dropdown(
                          key: ValueKey('region-$_region'),
                          label: l.fieldRegion,
                          value: uzbekistanRegions.containsKey(_region)
                              ? _region
                              : null,
                          items: {for (final r in uzbekistanRegions.keys) r: r},
                          onChanged: (v) => setState(() {
                            _region = v;
                            _district = null;
                          }),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _Dropdown(
                          key: ValueKey('district-$_region-$_district'),
                          label: l.fieldDistrict,
                          value:
                              _region != null &&
                                  districtsFor(_region).contains(_district)
                              ? _district
                              : null,
                          items: {for (final d in districtsFor(_region)) d: d},
                          onChanged: (v) => setState(() => _district = v),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        JzTextField(label: l.fieldCity, controller: _city),
                        const SizedBox(height: AppSpacing.md),
                        JzTextField(
                          label: l.fieldWorkAddress,
                          controller: _address,
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.map_outlined),
                          title: Text(l.pickOnMap),
                          subtitle: _lat != null && _lng != null
                              ? Text(
                                  '${_lat!.toStringAsFixed(5)}, '
                                  '${_lng!.toStringAsFixed(5)}',
                                )
                              : null,
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: _pickLocation,
                        ),
                      ],
                    ),

                    // ── 5. Ish haqida (About the job) ───────────────────────
                    _FormSection(
                      title: l.sectionAboutJob,
                      children: [
                        JzTextField(label: l.fieldSkills, controller: _skills),
                        const SizedBox(height: AppSpacing.md),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _generating ? null : _generate,
                            icon: _generating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 18,
                                  ),
                            label: Text(l.aiGenerate),
                            style: OutlinedButton.styleFrom(
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: context.colors.chipBackground,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: context.colors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  l.discriminationHint,
                                  style: context.text.bodySmall?.copyWith(
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _MarkdownToolbar(controller: _description),
                        JzTextField(
                          label: l.fieldDescription,
                          controller: _description,
                          maxLines: 4,
                          minLines: 3,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        JzTextField(
                          label: l.fieldResponsibilities,
                          controller: _responsibilities,
                          maxLines: 4,
                          minLines: 3,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        JzTextField(
                          label: l.fieldRequirements,
                          controller: _requirements,
                          maxLines: 4,
                          minLines: 3,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        JzTextField(
                          label: l.fieldBenefits,
                          controller: _benefits,
                          maxLines: 4,
                          minLines: 3,
                        ),
                      ],
                    ),

                    // ── 6. Saralash savollari (Screening questions) ──────────
                    _FormSection(
                      title: l.screeningSection,
                      children: [
                        _ScreeningEditor(
                          questions: _questions,
                          onChanged: (q) => setState(() => _questions = q),
                        ),
                      ],
                    ),

                    // ── 7. Javob sozlamalari (Response settings) ─────────────
                    _FormSection(
                      title: l.responseSettingsSection,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l.fieldRequireCoverLetter),
                          value: _requireCoverLetter,
                          onChanged: (v) =>
                              setState(() => _requireCoverLetter = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l.fieldAllowIncompleteResume),
                          subtitle: Text(l.fieldAllowIncompleteResumeHint),
                          value: _allowIncompleteResume,
                          onChanged: (v) =>
                              setState(() => _allowIncompleteResume = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l.fieldShowPhone),
                          value: _showPhone,
                          onChanged: (v) => setState(() => _showPhone = v),
                        ),
                        if (_showPhone) ...[
                          JzTextField(
                            label: l.fieldContactPhone,
                            controller: _contactPhone,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ],
                    ),

                    // ── Scheduled publish ────────────────────────────────────
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.schedulePublishLabel),
                      subtitle: Text(l.schedulePublishHint),
                      value: _scheduleOn,
                      onChanged: (v) => setState(() => _scheduleOn = v),
                    ),
                    if (_scheduleOn)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_outlined),
                        title: Text(
                          _publishAt == null
                              ? l.pickDateTime
                              : _fmtPublishAt(_publishAt!),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _pickPublishAt,
                      ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => _submit('draft'),
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                        ),
                        child: Text(l.saveDraft),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: JzPrimaryButton(
                        label: l.publishJob,
                        loading: _saving,
                        onPressed: () => _submit('open'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          hint: Text(l.selectOption),
          items: [
            for (final e in items.entries)
              DropdownMenuItem(value: e.key, child: Text(e.value)),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Collapsible card section for the post-job form. Wraps children in an
/// [ExpansionTile] inside a [Card] so the form stays scannable.
class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          title,
          style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        initiallyExpanded: initiallyExpanded,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// Repeatable editor for a job's screening questions. Emits a new list on
/// every change; empty-label rows are dropped on submit.
class _ScreeningEditor extends StatelessWidget {
  const _ScreeningEditor({required this.questions, required this.onChanged});

  final List<ScreeningQuestion> questions;
  final ValueChanged<List<ScreeningQuestion>> onChanged;

  void _set(int i, ScreeningQuestion q) => onChanged([...questions]..[i] = q);
  void _removeAt(int i) => onChanged([...questions]..removeAt(i));
  void _add() => onChanged([
    ...questions,
    ScreeningQuestion(
      id: 'q${DateTime.now().microsecondsSinceEpoch}',
      label: '',
    ),
  ]);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < questions.length; i++)
          Padding(
            key: ValueKey(questions[i].id),
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: questions[i].label,
                        decoration: InputDecoration(
                          hintText: l.questionTextHint,
                          isDense: true,
                        ),
                        onChanged: (v) =>
                            _set(i, questions[i].copyWith(label: v)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => _removeAt(i),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: questions[i].type,
                        isDense: true,
                        items: [
                          DropdownMenuItem(
                            value: 'text',
                            child: Text(l.qTypeText),
                          ),
                          DropdownMenuItem(
                            value: 'yesno',
                            child: Text(l.qTypeYesNo),
                          ),
                          DropdownMenuItem(
                            value: 'number',
                            child: Text(l.qTypeNumber),
                          ),
                          DropdownMenuItem(
                            value: 'multiple_choice',
                            child: Text(l.qTypeMultipleChoice),
                          ),
                        ],
                        onChanged: (v) =>
                            _set(i, questions[i].copyWith(type: v ?? 'text')),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    FilterChip(
                      label: Text(l.questionRequired),
                      selected: questions[i].required,
                      onSelected: (v) =>
                          _set(i, questions[i].copyWith(required: v)),
                    ),
                  ],
                ),
                // Options editor for multiple_choice type
                if (questions[i].type == 'multiple_choice') ...[
                  const SizedBox(height: AppSpacing.sm),
                  for (var j = 0; j < questions[i].options.length; j++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: ValueKey('${questions[i].id}-opt-$j'),
                              initialValue: questions[i].options[j],
                              decoration: InputDecoration(
                                hintText: '${l.optionLabel} ${j + 1}',
                                isDense: true,
                              ),
                              onChanged: (v) {
                                final opts = [...questions[i].options];
                                opts[j] = v;
                                _set(i, questions[i].copyWith(options: opts));
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              final opts = [...questions[i].options]
                                ..removeAt(j);
                              _set(i, questions[i].copyWith(options: opts));
                            },
                          ),
                        ],
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _set(
                        i,
                        questions[i].copyWith(
                          options: [...questions[i].options, ''],
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(l.addOption),
                    ),
                  ),
                ],
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l.addQuestion),
            style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
          ),
        ),
      ],
    );
  }
}

/// Repeatable editor for required languages (language + CEFR level). Language
/// names are shown as autonyms (no l10n); levels are A1–C2 plus "native".
class _LanguagesEditor extends StatelessWidget {
  const _LanguagesEditor({required this.languages, required this.onChanged});

  final List<JobLanguage> languages;
  final ValueChanged<List<JobLanguage>> onChanged;

  static const _options = {
    'uz': 'Oʻzbekcha',
    'ru': 'Русский',
    'en': 'English',
    'kk': 'Қазақша',
    'tr': 'Türkçe',
    'ar': 'العربية',
    'ko': '한국어',
    'zh': '中文',
    'de': 'Deutsch',
  };
  static const _levels = ['a1', 'a2', 'b1', 'b2', 'c1', 'c2', 'native'];

  void _set(int i, JobLanguage v) => onChanged([...languages]..[i] = v);
  void _removeAt(int i) => onChanged([...languages]..removeAt(i));
  void _add() =>
      onChanged([...languages, const JobLanguage(code: 'en', level: 'a1')]);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.languagesLabel, style: context.text.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < languages.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: _options.containsKey(languages[i].code)
                        ? languages[i].code
                        : null,
                    isDense: true,
                    isExpanded: true,
                    hint: Text(l.selectLanguage),
                    items: [
                      for (final e in _options.entries)
                        DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ],
                    onChanged: (v) =>
                        _set(i, languages[i].copyWith(code: v ?? 'en')),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _levels.contains(languages[i].level)
                        ? languages[i].level
                        : null,
                    isDense: true,
                    isExpanded: true,
                    items: [
                      for (final lvl in _levels)
                        DropdownMenuItem(
                          value: lvl,
                          child: Text(
                            lvl == 'native' ? l.cefrNative : lvl.toUpperCase(),
                          ),
                        ),
                    ],
                    onChanged: (v) =>
                        _set(i, languages[i].copyWith(level: v ?? 'a1')),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => _removeAt(i),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l.addLanguage),
            style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
          ),
        ),
      ],
    );
  }
}

/// Minimal markdown formatting toolbar for the description field. Inserts
/// markdown into [controller] at the selection; the seeker job-details renders
/// it formatted (see job_details_page `MarkdownBody`).
class _MarkdownToolbar extends StatelessWidget {
  const _MarkdownToolbar({required this.controller});

  final TextEditingController controller;

  void _apply(MarkdownEdit Function(String, TextSelection) op) {
    final v = controller.value;
    final r = op(v.text, v.selection);
    controller.value = TextEditingValue(text: r.text, selection: r.selection);
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textSecondary;
    Widget btn(
      IconData icon,
      MarkdownEdit Function(String, TextSelection) op,
    ) => IconButton(
      icon: Icon(icon, size: 20),
      color: color,
      visualDensity: VisualDensity.compact,
      onPressed: () => _apply(op),
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.format_bold_rounded, (t, s) => mdWrap(t, s, '**')),
          btn(Icons.format_italic_rounded, (t, s) => mdWrap(t, s, '*')),
          btn(
            Icons.format_list_bulleted_rounded,
            (t, s) => mdLinePrefix(t, s, '- '),
          ),
          btn(
            Icons.format_list_numbered_rounded,
            (t, s) => mdLinePrefix(t, s, '1. '),
          ),
        ],
      ),
    );
  }
}
