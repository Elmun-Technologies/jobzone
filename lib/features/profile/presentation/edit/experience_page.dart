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

/// List of work experiences with add / edit / delete.
class ExperienceListPage extends ConsumerWidget {
  const ExperienceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(experiencesControllerProvider);
    return CvSectionScaffold<Experience>(
      title: l.sectionExperience,
      async: async,
      emptyTitle: l.noEntriesYet,
      emptyBody: l.experienceEmptyBody,
      emptyIcon: Icons.work_outline_rounded,
      onAdd: () => _openEditor(context),
      itemBuilder: (c, e) => CvEntryCard(
        title: e.title,
        subtitle: [
          e.companyName,
          periodText(c, e.startDate, e.endDate, current: e.isCurrent),
        ].where((s) => s != null && s.isNotEmpty).join(' • '),
        detail: e.description,
        onTap: () => _openEditor(context, e),
      ),
    );
  }

  void _openEditor(BuildContext context, [Experience? existing]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ExperienceEditPage(existing: existing)),
    );
  }
}

class ExperienceEditPage extends ConsumerStatefulWidget {
  const ExperienceEditPage({super.key, this.existing});
  final Experience? existing;

  @override
  ConsumerState<ExperienceEditPage> createState() => _ExperienceEditPageState();
}

class _ExperienceEditPageState extends ConsumerState<ExperienceEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _company;
  late final TextEditingController _location;
  late final TextEditingController _description;
  DateTime? _start;
  DateTime? _end;
  bool _current = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title);
    _company = TextEditingController(text: e?.companyName);
    _location = TextEditingController(text: e?.location);
    _description = TextEditingController(text: e?.description);
    _start = e?.startDate;
    _end = e?.endDate;
    _current = e?.isCurrent ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _company.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final entry = Experience(
      id: widget.existing?.id,
      title: _title.text.trim(),
      companyName: _nullable(_company.text),
      location: _nullable(_location.text),
      startDate: _start,
      endDate: _end,
      isCurrent: _current,
      description: _nullable(_description.text),
    );
    try {
      await ref.read(experiencesControllerProvider.notifier).save(entry);
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
      await ref.read(experiencesControllerProvider.notifier).remove(id);
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
      title: widget.existing == null ? l.addExperience : l.editExperience,
      formKey: _formKey,
      saving: _saving,
      onSave: _save,
      onDelete: widget.existing == null ? null : _delete,
      children: [
        JzTextField(
          label: l.jobTitleLabel,
          controller: _title,
          textInputAction: TextInputAction.next,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? l.valRequired : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        JzTextField(label: l.companyLabel, controller: _company),
        const SizedBox(height: AppSpacing.lg),
        JzTextField(label: l.locationLabel, controller: _location),
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
          enabled: !_current,
          hint: _current ? l.present : null,
          onChanged: (d) => setState(() => _end = d),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.currentlyWorkHere),
          value: _current,
          onChanged: (v) => setState(() {
            _current = v;
            if (v) _end = null;
          }),
        ),
        const SizedBox(height: AppSpacing.sm),
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
