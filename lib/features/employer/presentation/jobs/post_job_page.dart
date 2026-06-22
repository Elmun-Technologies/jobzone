import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/validators.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/enums/enums.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../../jobs/data/categories_repository.dart';
import '../../../jobs/domain/job.dart';
import '../../../jobs/domain/job_language.dart';
import '../../../jobs/domain/screening_question.dart';
import '../../../monetization/presentation/promote_sheet.dart';
import '../../data/ai_content_repository.dart';
import '../../data/employer_jobs_repository.dart';
import 'widgets/job_location_picker.dart';

/// Driver-license categories offered as chips on the post-job form.
const _kLicenseCategories = [
  'A',
  'B',
  'C',
  'D',
  'E',
  'BE',
  'CE',
  'DE',
  'TM',
  'TB',
];

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
      final d = await ref
          .read(aiContentRepositoryProvider)
          .draftJob(
            title: _title.text.trim(),
            category: _categoryId,
            jobType: _type,
            skills: skills,
          );
      if (!mounted) return;
      setState(() {
        _description.text = d.description;
        _responsibilities.text = d.responsibilities;
        _requirements.text = d.requirements;
        _benefits.text = d.benefits;
      });
    } catch (e) {
      if (mounted) showErrorSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _generating = false);
    }
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
            salaryMin: num.tryParse(_min.text),
            salaryMax: num.tryParse(_max.text),
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
            city: _city.text.trim(),
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
          ),
        );
      } else {
        created = await repo.createJob(
          title: _title.text.trim(),
          jobType: _type,
          experienceLevel: _level,
          workingModel: _model,
          salaryMin: num.tryParse(_min.text),
          salaryMax: num.tryParse(_max.text),
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
          city: _city.text.trim(),
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
      if (mounted) showErrorSnack(context, e.toString());
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
              child: JzTopBar(title: _isEdit ? l.editJobTitle : l.postJobCta),
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
                    JzTextField(
                      label: l.fieldJobTitle,
                      controller: _title,
                      validator: (v) =>
                          Validators.isNotBlank(v) ? null : l.valRequired,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _Dropdown(
                      key: ValueKey('cat-${_categoryId ?? ''}-${cats.length}'),
                      label: l.jobCategory,
                      value: cats.any((c) => c.id == _categoryId)
                          ? _categoryId
                          : null,
                      items: {for (final c in cats) c.id: c.name},
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
                    const SizedBox(height: AppSpacing.lg),
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
                    const SizedBox(height: AppSpacing.lg),
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
                    const SizedBox(height: AppSpacing.lg),
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
                    const SizedBox(height: AppSpacing.lg),
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
                    const SizedBox(height: AppSpacing.lg),
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
                      onChanged: (v) => setState(() => _disabilityFriendly = v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
                    const SizedBox(height: AppSpacing.lg),
                    _Dropdown(
                      label: l.currencyLabel,
                      value: _currency,
                      items: {'UZS': l.currencyUzs, 'USD': l.currencyUsd},
                      onChanged: (v) => setState(() => _currency = v ?? 'UZS'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
                    const SizedBox(height: AppSpacing.lg),
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
                    const SizedBox(height: AppSpacing.lg),
                    JzTextField(label: l.fieldCity, controller: _city),
                    const SizedBox(height: AppSpacing.lg),
                    JzTextField(
                      label: l.fieldWorkAddress,
                      controller: _address,
                    ),
                    const SizedBox(height: AppSpacing.sm),
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
                    const SizedBox(height: AppSpacing.lg),
                    JzTextField(label: l.fieldSkills, controller: _skills),
                    const SizedBox(height: AppSpacing.lg),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.driverLicenseLabel,
                          style: context.text.labelLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: [
                            for (final c in _kLicenseCategories)
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
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _LanguagesEditor(
                      languages: _languages,
                      onChanged: (v) => setState(() => _languages = v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
                            : const Icon(Icons.auto_awesome_rounded, size: 18),
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
                    JzTextField(
                      label: l.fieldDescription,
                      controller: _description,
                      maxLines: 4,
                      minLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    JzTextField(
                      label: l.fieldResponsibilities,
                      controller: _responsibilities,
                      maxLines: 4,
                      minLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    JzTextField(
                      label: l.fieldRequirements,
                      controller: _requirements,
                      maxLines: 4,
                      minLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    JzTextField(
                      label: l.fieldBenefits,
                      controller: _benefits,
                      maxLines: 4,
                      minLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ScreeningEditor(
                      questions: _questions,
                      onChanged: (q) => setState(() => _questions = q),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l.responseSettingsSection,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.fieldRequireCoverLetter),
                      value: _requireCoverLetter,
                      onChanged: (v) => setState(() => _requireCoverLetter = v),
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
                      const SizedBox(height: AppSpacing.sm),
                      JzTextField(
                        label: l.fieldContactPhone,
                        controller: _contactPhone,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
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

/// Repeatable editor for a job's screening questions (label + type + required).
/// Emits a new list on every change; empty-label rows are dropped on submit.
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
        Text(l.screeningSection, style: context.text.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < questions.length; i++)
          Padding(
            key: ValueKey(questions[i].id),
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
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
