import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/enums/enums.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../../jobs/data/categories_repository.dart';
import '../../../jobs/domain/job.dart';
import '../../data/employer_jobs_repository.dart';

/// Create or edit a job posting. Pass [job] (via the edit route's `extra`) to
/// prefill the form for editing; omit it to create a new posting.
class PostJobPage extends ConsumerStatefulWidget {
  const PostJobPage({super.key, this.job});

  final Job? job;

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
  bool _saving = false;

  bool get _isEdit => widget.job != null;

  @override
  void dispose() {
    _title.dispose();
    _city.dispose();
    _min.dispose();
    _max.dispose();
    _skills.dispose();
    _description.dispose();
    _requirements.dispose();
    super.dispose();
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
    try {
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
            currency: _currency,
            categoryId: _categoryId,
            city: _city.text.trim(),
            skills: skills,
            description: _description.text.trim(),
            requirements: _requirements.text.trim(),
            status: status,
          ),
        );
      } else {
        await repo.createJob(
          title: _title.text.trim(),
          jobType: _type,
          experienceLevel: _level,
          workingModel: _model,
          salaryMin: num.tryParse(_min.text),
          salaryMax: num.tryParse(_max.text),
          salaryPeriod: _payType,
          payoutFrequency: _payoutFreq,
          currency: _currency,
          categoryId: _categoryId,
          city: _city.text.trim(),
          skills: skills,
          description: _description.text.trim(),
          requirements: _requirements.text.trim(),
          status: status,
        );
      }
      ref.invalidate(myJobsProvider);
      if (mounted) {
        showInfoSnack(context, context.l10n.jobSavedToast);
        context.pop();
      }
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
                    JzTextField(label: l.fieldSkills, controller: _skills),
                    const SizedBox(height: AppSpacing.lg),
                    JzTextField(
                      label: l.fieldDescription,
                      controller: _description,
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
