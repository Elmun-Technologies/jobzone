import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../application/cv_providers.dart';
import '../../domain/cv_models.dart';
import 'util/cv_format.dart';
import 'widgets/cv_section_scaffold.dart';
import 'widgets/date_field.dart';
import 'widgets/edit_form_scaffold.dart';

class EducationListPage extends ConsumerWidget {
  const EducationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(educationsControllerProvider);
    return CvSectionScaffold<Education>(
      title: l.sectionEducation,
      async: async,
      emptyTitle: l.noEntriesYet,
      emptyBody: l.educationEmptyBody,
      emptyIcon: Icons.school_outlined,
      onAdd: () => _openEditor(context),
      itemBuilder: (c, e) => CvEntryCard(
        title: e.school,
        subtitle: [
          [
            e.degree,
            e.field,
          ].where((s) => s != null && s.isNotEmpty).join(', '),
          periodText(c, e.startDate, e.endDate),
        ].where((s) => s.isNotEmpty).join(' • '),
        detail: e.description,
        onTap: () => _openEditor(context, e),
      ),
    );
  }

  void _openEditor(BuildContext context, [Education? existing]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EducationEditPage(existing: existing)),
    );
  }
}

class EducationEditPage extends ConsumerStatefulWidget {
  const EducationEditPage({super.key, this.existing});
  final Education? existing;

  @override
  ConsumerState<EducationEditPage> createState() => _EducationEditPageState();
}

class _EducationEditPageState extends ConsumerState<EducationEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _school;
  late final TextEditingController _degree;
  late final TextEditingController _field;
  late final TextEditingController _grade;
  late final TextEditingController _description;
  DateTime? _start;
  DateTime? _end;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _school = TextEditingController(text: e?.school);
    _degree = TextEditingController(text: e?.degree);
    _field = TextEditingController(text: e?.field);
    _grade = TextEditingController(text: e?.grade);
    _description = TextEditingController(text: e?.description);
    _start = e?.startDate;
    _end = e?.endDate;
  }

  @override
  void dispose() {
    _school.dispose();
    _degree.dispose();
    _field.dispose();
    _grade.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final entry = Education(
      id: widget.existing?.id,
      school: _school.text.trim(),
      degree: _nullable(_degree.text),
      field: _nullable(_field.text),
      grade: _nullable(_grade.text),
      startDate: _start,
      endDate: _end,
      description: _nullable(_description.text),
    );
    try {
      await ref.read(educationsControllerProvider.notifier).save(entry);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final id = widget.existing?.id;
    if (id == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(educationsControllerProvider.notifier).remove(id);
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
    return EditFormScaffold(
      title: widget.existing == null ? l.addEducation : l.editEducation,
      formKey: _formKey,
      saving: _saving,
      onSave: _save,
      onDelete: widget.existing == null ? null : _delete,
      children: [
        JzTextField(
          label: l.schoolLabel,
          controller: _school,
          textInputAction: TextInputAction.next,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? l.valRequired : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        JzTextField(label: l.degreeLabel, controller: _degree),
        const SizedBox(height: AppSpacing.lg),
        JzTextField(label: l.fieldOfStudyLabel, controller: _field),
        const SizedBox(height: AppSpacing.lg),
        JzTextField(label: l.gradeLabel, controller: _grade),
        const SizedBox(height: AppSpacing.lg),
        DateField(
          label: l.startDate,
          value: _start,
          onChanged: (d) => setState(() => _start = d),
        ),
        const SizedBox(height: AppSpacing.lg),
        DateField(
          label: l.endDate,
          value: _end,
          onChanged: (d) => setState(() => _end = d),
        ),
        const SizedBox(height: AppSpacing.lg),
        JzTextField(
          label: l.descriptionLabel,
          controller: _description,
          hint: l.descriptionHint,
          maxLines: 4,
          minLines: 3,
        ),
      ],
    );
  }
}

String? _nullable(String s) => s.trim().isEmpty ? null : s.trim();
