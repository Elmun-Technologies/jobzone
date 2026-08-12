import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/env.dart';
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
import '../../data/ai_content_repository.dart';
import '../../data/employer_jobs_repository.dart';
import '../../domain/publish_gate.dart';
import 'listing_payment_page.dart';
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

  // One controller per collapsible _FormSection, so a failed validate() can
  // force every section open. Every section keeps its fields mounted while
  // collapsed specifically so validators still run (see _FormSection's own
  // comment) — but a validator failing inside a section nobody opened, e.g.
  // the required salary field, used to be invisible: validate() returned
  // false, _submit returned, and the button just looked dead. Flutter's
  // ExpansionTile is otherwise uncontrolled, so without this there is no way
  // to open a section from outside a user tap.
  final _sectionControllers = List.generate(7, (_) => ExpansibleController());
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
  // Left empty on a new vacancy. This used to default to '18' and was written
  // unconditionally, so every mobile posting carried an age floor the employer
  // never chose — on the same screen that warns them not to discriminate by
  // age. An empty field means "no limit", which is the honest default.
  late final _ageMin = TextEditingController(
    text: widget.job?.ageMin?.toString(),
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

  /// The value that goes into `jobs.city`.
  ///
  /// Used to be `_district ?? _city.text.trim()` — the picked DISTRICT
  /// (e.g. `'Chilonzor'`) whenever one was selected, which is a different
  /// vocabulary than what the seeker's city filter, the onboarding city
  /// picker and `recommended_jobs()` compare against (see
  /// `regionToCityOption`'s doc comment). `district` is already written to
  /// its own column right alongside this, so nothing about the district
  /// choice is lost by not also overloading `city` with it.
  ///
  /// Prefers whatever the employer actually typed into the free-text City
  /// field (respects real intent, e.g. a specific neighbourhood name);
  /// otherwise the region's matching filter option for the 7 regions that
  /// have one; otherwise the bare region name — still wrong for an exact
  /// seeker-filter match, but at least a real, consistent place name instead
  /// of an arbitrary district that could belong to any region.
  String _effectiveCity() {
    final typed = _city.text.trim();
    if (typed.isNotEmpty) return typed;
    return regionToCityOption[_region] ?? _region ?? '';
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
      // Typing beats scrolling — same rationale as the profile DateField.
      initialEntryMode: DatePickerEntryMode.input,
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
    final hasExisting =
        _description.text.trim().isNotEmpty ||
        _responsibilities.text.trim().isNotEmpty ||
        _requirements.text.trim().isNotEmpty ||
        _benefits.text.trim().isNotEmpty;
    if (hasExisting) {
      final l = context.l10n;
      final replace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.aiOverwriteConfirmTitle),
          content: Text(l.aiOverwriteConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l.aiGenerate),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
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
      city: _effectiveCity(),
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
    if (!_formKey.currentState!.validate()) {
      // Every section keeps its fields mounted while collapsed so validators
      // still run against them — but a failing field the user never opened
      // (the required salary is the common case) rendered its error text
      // inside an invisible tile, and the "E'lon qilish" button just looked
      // dead. Force every section open and say plainly that something needs
      // attention.
      for (final c in _sectionControllers) {
        if (!c.isExpanded) c.expand();
      }
      showErrorSnack(context, context.l10n.formHasErrors);
      return;
    }
    if (_salaryDisplay == 'exact') {
      final min = num.tryParse(_min.text);
      final max = num.tryParse(_max.text);
      if (min != null && max != null && max < min) {
        showErrorSnack(context, context.l10n.valSalaryMaxLessMin);
        return;
      }
    }
    if (_scheduleOn &&
        (_publishAt == null || !_publishAt!.isAfter(DateTime.now()))) {
      showErrorSnack(context, context.l10n.scheduleDateRequired);
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(employerJobsRepositoryProvider);
    final skills = _skills.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final scheduled =
        _scheduleOn &&
        _publishAt != null &&
        _publishAt!.isAfter(DateTime.now());
    final effectiveStatus = status == 'open' && scheduled ? 'draft' : status;
    final publishAt = scheduled ? _publishAt : null;
    try {
      // Direct pay-per-listing: the first published vacancy is free; a 2nd+
      // one is created as a DRAFT and paid per listing (tier + Payme/Click) on
      // the next screen, which publishes it. Offline has no charge path, so the
      // demo always free-publishes.
      //
      // The gate keys off the employer's INTENT to enter the market (they hit
      // "E'lon qilish"), not off the row's effective status — see
      // isChargeableMarketEntry, which mirrors guard_job_publish() (0066):
      //
      //   * a scheduled post is a draft until its time, but it is still a
      //     market entry. Gating on effectiveStatus meant a 2nd+ scheduled
      //     vacancy created no order, said "rejalashtirildi", and was then
      //     parked unpublished by publish_due_jobs() when its time came.
      //     Charging up front makes publish_due_jobs() find a paid tier order
      //     and take it live on schedule (0076 keeps payment from publishing
      //     a scheduled draft early).
      //   * editing is not exempt either. `!_isEdit` skipped the gate whenever
      //     a draft was published from THIS screen, so the update wrote
      //     status='open' directly and the DB guard raised `payment_required`
      //     — surfacing as a bare "Xatolik yuz berdi" with no way forward.
      final charged =
          Env.hasSupabase &&
          isChargeableMarketEntry(
            wantsToGoLive: status == 'open',
            isEdit: _isEdit,
            firstPublishedAt: widget.job?.firstPublishedAt,
            currentStatus: widget.job?.status,
          ) &&
          await repo.hasPublishedBefore();
      // While it is unpaid the row must stay a draft — including the edit
      // path, which would otherwise trip the guard.
      final createStatus = charged ? 'draft' : effectiveStatus;
      Job? created;
      if (_isEdit) {
        // Keep the job a draft when charged — the fields still save, but the
        // status transition to 'open' happens only once payment clears, on
        // the same ListingPaymentPage the create path uses below.
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
            city: _effectiveCity(),
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
            status: createStatus,
            publishAt: publishAt,
            educationRequired: _educationRequired,
            workHours: _workHours.text.trim().isEmpty
                ? null
                : _workHours.text.trim(),
          ),
        );
        if (!mounted) return;
        if (charged) {
          // Same checkout as a brand-new 2nd+ vacancy: the edited fields are
          // already saved (as a draft, above); this only needs to flip status
          // once payment clears.
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => ListingPaymentPage(jobId: widget.job!.id),
            ),
          );
        } else {
          context.pop();
        }
      } else {
        created = await repo.createJob(
          title: _title.text.trim(),
          jobType: _type,
          experienceLevel: _level,
          workingModel: _model,
          salaryMin: _salaryDisplay == 'exact' ? num.tryParse(_min.text) : null,
          salaryMax: _salaryDisplay == 'exact' ? num.tryParse(_max.text) : null,
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
          city: _effectiveCity(),
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
          status: createStatus,
          publishAt: publishAt,
          educationRequired: _educationRequired,
          workHours: _workHours.text.trim().isEmpty ? null : _workHours.text.trim(),
        );
        if (!mounted) return;
        if (charged) {
          await Navigator.of(context).pushReplacement<bool, void>(
            MaterialPageRoute(
              builder: (_) => ListingPaymentPage(jobId: created!.id),
            ),
          );
        } else {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, localizedError(context, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return JzScaffold(
      title: _isEdit ? l.editJobTitle : l.postJobTitle,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _FormSection(
              title: l.jobBasicInfo,
              controller: _sectionControllers[0],
              children: [
                JzTextField(
                  controller: _title,
                  label: l.jobTitle,
                  hint: l.jobTitleHint,
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? l.valRequired : null,
                ),
                const SizedBox(height: AppSpacing.md),
                JzDropdownField<String>(
                  value: _categoryId,
                  label: l.jobCategory,
                  items: [
                    for (final c in ref.watch(jobCategoriesProvider).value ??
                        const <JobCategory>[])
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                  validator: (v) => v == null ? l.valRequired : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: JzDropdownField<String>(
                        value: _type,
                        label: l.jobType,
                        items: [
                          DropdownMenuItem(
                            value: 'full_time',
                            child: Text(l.jobTypeFullTime),
                          ),
                          DropdownMenuItem(
                            value: 'part_time',
                            child: Text(l.jobTypePartTime),
                          ),
                          DropdownMenuItem(
                            value: 'internship',
                            child: Text(l.jobTypeInternship),
                          ),
                          DropdownMenuItem(
                            value: 'rotational',
                            child: Text(l.jobTypeRotational),
                          ),
                        ],
                        onChanged: (v) => setState(() => _type = v),
                        validator: (v) => v == null ? l.valRequired : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: JzDropdownField<String>(
                        value: _level,
                        label: l.jobExperience,
                        items: [
                          DropdownMenuItem(
                            value: 'entry',
                            child: Text(l.expEntry),
                          ),
                          DropdownMenuItem(
                            value: 'junior',
                            child: Text(l.expJunior),
                          ),
                          DropdownMenuItem(
                            value: 'mid',
                            child: Text(l.expMid),
                          ),
                          DropdownMenuItem(
                            value: 'senior',
                            child: Text(l.expSenior),
                          ),
                          DropdownMenuItem(
                            value: 'lead',
                            child: Text(l.expLead),
                          ),
                        ],
                        onChanged: (v) => setState(() => _level = v),
                        validator: (v) => v == null ? l.valRequired : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _FormSection(
              title: l.jobSalaryAndConditions,
              controller: _sectionControllers[1],
              children: [
                Row(
                  children: [
                    Expanded(
                      child: JzDropdownField<String>(
                        value: _salaryDisplay,
                        label: l.salaryDisplay,
                        items: [
                          DropdownMenuItem(
                            value: 'exact',
                            child: Text(l.salaryExact),
                          ),
                          DropdownMenuItem(
                            value: 'negotiable',
                            child: Text(l.salaryNegotiable),
                          ),
                        ],
                        onChanged: (v) => setState(() => _salaryDisplay = v!),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: JzDropdownField<String>(
                        value: _currency,
                        label: l.currency,
                        items: const [
                          DropdownMenuItem(value: 'UZS', child: Text('UZS')),
                          DropdownMenuItem(value: 'USD', child: Text('USD')),
                        ],
                        onChanged: (v) => setState(() => _currency = v!),
                      ),
                    ),
                  ],
                ),
                if (_salaryDisplay == 'exact') ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: JzTextField(
                          controller: _min,
                          label: l.salaryMin,
                          keyboardType: TextInputType.number,
                          validator: (v) => (v?.trim().isEmpty ?? true)
                              ? l.valRequired
                              : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: JzTextField(
                          controller: _max,
                          label: l.salaryMax,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: JzDropdownField<String>(
                        value: _payType,
                        label: l.salaryPeriod,
                        items: [
                          DropdownMenuItem(
                            value: 'monthly',
                            child: Text(l.periodMonthly),
                          ),
                          DropdownMenuItem(
                            value: 'hourly',
                            child: Text(l.periodHourly),
                          ),
                          DropdownMenuItem(
                            value: 'daily',
                            child: Text(l.periodDaily),
                          ),
                          DropdownMenuItem(
                            value: 'project',
                            child: Text(l.periodProject),
                          ),
                        ],
                        onChanged: (v) => setState(() => _payType = v),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: JzDropdownField<String>(
                        value: _payoutFreq,
                        label: l.payoutFrequency,
                        items: [
                          DropdownMenuItem(
                            value: 'once_a_month',
                            child: Text(l.freqOnceMonth),
                          ),
                          DropdownMenuItem(
                            value: 'twice_a_month',
                            child: Text(l.freqTwiceMonth),
                          ),
                          DropdownMenuItem(
                            value: 'weekly',
                            child: Text(l.freqWeekly),
                          ),
                          DropdownMenuItem(
                            value: 'daily',
                            child: Text(l.freqDaily),
                          ),
                        ],
                        onChanged: (v) => setState(() => _payoutFreq = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: JzDropdownField<String>(
                        value: _model,
                        label: l.workingModel,
                        items: [
                          DropdownMenuItem(
                            value: 'on_site',
                            child: Text(l.modelOnSite),
                          ),
                          DropdownMenuItem(
                            value: 'remote',
                            child: Text(l.modelRemote),
                          ),
                          DropdownMenuItem(
                            value: 'hybrid',
                            child: Text(l.modelHybrid),
                          ),
                        ],
                        onChanged: (v) => setState(() => _model = v),
                        validator: (v) => v == null ? l.valRequired : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: JzDropdownField<String>(
                        value: _schedule,
                        label: l.schedulePattern,
                        items: [
                          DropdownMenuItem(
                            value: '5_2',
                            child: Text(l.schedule52),
                          ),
                          DropdownMenuItem(
                            value: '6_1',
                            child: Text(l.schedule61),
                          ),
                          DropdownMenuItem(
                            value: '2_2',
                            child: Text(l.schedule22),
                          ),
                          DropdownMenuItem(
                            value: 'flexible',
                            child: Text(l.scheduleFlexible),
                          ),
                        ],
                        onChanged: (v) => setState(() => _schedule = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                JzCheckboxField(
                  value: _salaryGross,
                  label: l.salaryGross,
                  onChanged: (v) => setState(() => _salaryGross = v!),
                ),
                JzCheckboxField(
                  value: _nightShift,
                  label: l.nightShift,
                  onChanged: (v) => setState(() => _nightShift = v!),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _FormSection(
              title: l.jobLocation,
              controller: _sectionControllers[2],
              children: [
                Row(
                  children: [
                    Expanded(
                      child: JzDropdownField<String>(
                        value: _region,
                        label: l.region,
                        items: [
                          for (final r in uzbekistanRegions)
                            DropdownMenuItem(value: r, child: Text(r)),
                        ],
                        onChanged: (v) => setState(() {
                          _region = v;
                          _district = null;
                        }),
                        validator: (v) => v == null ? l.valRequired : null,
                      ),
                    ),
                    if (_region != null &&
                        uzbekistanDistricts.containsKey(_region)) ...[
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: JzDropdownField<String>(
                          value: _district,
                          label: l.district,
                          items: [
                            for (final d in uzbekistanDistricts[_region]!)
                              DropdownMenuItem(value: d, child: Text(d)),
                          ],
                          onChanged: (v) => setState(() => _district = v),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                JzTextField(
                  controller: _city,
                  label: l.city,
                  hint: l.cityHint,
                ),
                const SizedBox(height: AppSpacing.md),
                JzTextField(
                  controller: _address,
                  label: l.address,
                  hint: l.addressHint,
                ),
                const SizedBox(height: AppSpacing.md),
                JzPrimaryButton(
                  label: _lat != null ? l.locationPicked : l.pickLocation,
                  onPressed: _pickLocation,
                  variant: JzButtonVariant.outline,
                  icon: Icons.map_outlined,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _FormSection(
              title: l.jobDetails,
              controller: _sectionControllers[3],
              children: [
                Row(
                  children: [
                    Text(
                      l.jobDescription,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _generating ? null : _generate,
                      icon: _generating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      tooltip: l.aiGenerate,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                JzTextField(
                  controller: _description,
                  maxLines: 8,
                  hint: l.jobDescriptionHint,
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? l.valRequired : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l.jobResponsibilities,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                JzTextField(
                  controller: _responsibilities,
                  maxLines: 5,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l.jobRequirements,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                JzTextField(
                  controller: _requirements,
                  maxLines: 5,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l.jobBenefits,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                JzTextField(
                  controller: _benefits,
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.md),
                JzTextField(
                  controller: _skills,
                  label: l.jobSkills,
                  hint: l.jobSkillsHint,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _FormSection(
              title: l.jobRequirementsAndFilters,
              controller: _sectionControllers[4],
              children: [
                Row(
                  children: [
                    Expanded(
                      child: JzTextField(
                        controller: _ageMin,
                        label: l.ageMin,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: JzTextField(
                        controller: _ageMax,
                        label: l.ageMax,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                JzDropdownField<String>(
                  value: _preferredGender,
                  label: l.preferredGender,
                  items: [
                    DropdownMenuItem(value: 'any', child: Text(l.genderAny)),
                    DropdownMenuItem(value: 'male', child: Text(l.genderMale)),
                    DropdownMenuItem(
                      value: 'female',
                      child: Text(l.genderFemale),
                    ),
                  ],
                  onChanged: (v) => setState(() => _preferredGender = v!),
                ),
                const SizedBox(height: AppSpacing.md),
                JzDropdownField<String>(
                  value: _educationRequired,
                  label: l.educationRequired,
                  items: [
                    DropdownMenuItem(value: 'none', child: Text(l.eduNone)),
                    DropdownMenuItem(
                      value: 'secondary',
                      child: Text(l.eduSecondary),
                    ),
                    DropdownMenuItem(
                      value: 'higher',
                      child: Text(l.eduHigher),
                    ),
                  ],
                  onChanged: (v) => setState(() => _educationRequired = v!),
                ),
                const SizedBox(height: AppSpacing.md),
                JzCheckboxField(
                  value: _womenFriendly,
                  label: l.womenFriendly,
                  onChanged: (v) => setState(() => _womenFriendly = v!),
                ),
                JzCheckboxField(
                  value: _disabilityFriendly,
                  label: l.disabilityFriendly,
                  onChanged: (v) => setState(() => _disabilityFriendly = v!),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _FormSection(
              title: l.jobApplicationProcess,
              controller: _sectionControllers[5],
              children: [
                JzCheckboxField(
                  value: _requireCoverLetter,
                  label: l.requireCoverLetter,
                  onChanged: (v) => setState(() => _requireCoverLetter = v!),
                ),
                JzCheckboxField(
                  value: _allowIncompleteResume,
                  label: l.allowIncompleteResume,
                  onChanged: (v) => setState(() => _allowIncompleteResume = v!),
                ),
                const SizedBox(height: AppSpacing.md),
                JzCheckboxField(
                  value: _showPhone,
                  label: l.showPhoneOnListing,
                  onChanged: (v) => setState(() => _showPhone = v!),
                ),
                if (_showPhone) ...[
                  const SizedBox(height: AppSpacing.sm),
                  JzTextField(
                    controller: _contactPhone,
                    label: l.contactPhone,
                    keyboardType: TextInputType.phone,
                    validator: (v) => (_showPhone && (v?.trim().isEmpty ?? true))
                        ? l.valRequired
                        : null,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _FormSection(
              title: l.jobPublishing,
              controller: _sectionControllers[6],
              children: [
                JzCheckboxField(
                  value: _scheduleOn,
                  label: l.schedulePublish,
                  onChanged: (v) => setState(() => _scheduleOn = v!),
                ),
                if (_scheduleOn) ...[
                  const SizedBox(height: AppSpacing.sm),
                  JzPrimaryButton(
                    label: _publishAt != null
                        ? _fmtPublishAt(_publishAt!)
                        : l.pickDate,
                    onPressed: _pickPublishAt,
                    variant: JzButtonVariant.outline,
                    icon: Icons.calendar_today_outlined,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: JzPrimaryButton(
                    label: l.preview,
                    onPressed: _preview,
                    variant: JzButtonVariant.outline,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: JzPrimaryButton(
                    label: _isEdit ? l.saveChanges : l.postJob,
                    onPressed: _saving ? null : () => _submit('open'),
                    loading: _saving,
                  ),
                ),
              ],
            ),
            if (!_isEdit) ...[
              const SizedBox(height: AppSpacing.md),
              JzPrimaryButton(
                label: l.saveAsDraft,
                onPressed: _saving ? null : () => _submit('draft'),
                variant: JzButtonVariant.ghost,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.children,
    required this.controller,
  });

  final String title;
  final List<Widget> children;
  final ExpansibleController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.colors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          controller: controller,
          initiallyExpanded: true,
          maintainState: true,
          title: Text(
            title,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class ExpansibleController extends ExpansionTileController {
  // Simple extension to track expanded state since the base controller
  // doesn't expose it.
  bool _isExpanded = true;
  bool get isExpanded => _isExpanded;

  @override
  void expand() {
    super.expand();
    _isExpanded = true;
  }

  @override
  void collapse() {
    super.collapse();
    _isExpanded = false;
  }
}
