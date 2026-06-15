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

class ProjectsListPage extends ConsumerWidget {
  const ProjectsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(projectsControllerProvider);
    return CvSectionScaffold<Project>(
      title: l.sectionProjects,
      async: async,
      emptyTitle: l.noEntriesYet,
      emptyBody: l.projectsEmptyBody,
      emptyIcon: Icons.lightbulb_outline_rounded,
      onAdd: () => _openEditor(context),
      itemBuilder: (c, e) => CvEntryCard(
        title: e.name,
        subtitle: [
          e.role,
          periodText(c, e.startDate, e.endDate),
        ].where((s) => s != null && s.isNotEmpty).join(' • '),
        detail: e.description,
        onTap: () => _openEditor(context, e),
      ),
    );
  }

  void _openEditor(BuildContext context, [Project? existing]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProjectEditPage(existing: existing)),
    );
  }
}

class ProjectEditPage extends ConsumerStatefulWidget {
  const ProjectEditPage({super.key, this.existing});
  final Project? existing;

  @override
  ConsumerState<ProjectEditPage> createState() => _ProjectEditPageState();
}

class _ProjectEditPageState extends ConsumerState<ProjectEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _role;
  late final TextEditingController _url;
  late final TextEditingController _description;
  DateTime? _start;
  DateTime? _end;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name);
    _role = TextEditingController(text: e?.role);
    _url = TextEditingController(text: e?.url);
    _description = TextEditingController(text: e?.description);
    _start = e?.startDate;
    _end = e?.endDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _url.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final entry = Project(
      id: widget.existing?.id,
      name: _name.text.trim(),
      role: _nullable(_role.text),
      url: _nullable(_url.text),
      startDate: _start,
      endDate: _end,
      description: _nullable(_description.text),
    );
    try {
      await ref.read(projectsControllerProvider.notifier).save(entry);
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
      await ref.read(projectsControllerProvider.notifier).remove(id);
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
      title: widget.existing == null ? l.addProject : l.editProject,
      formKey: _formKey,
      saving: _saving,
      onSave: _save,
      onDelete: widget.existing == null ? null : _delete,
      children: [
        JzTextField(
          label: l.projectNameLabel,
          controller: _name,
          textInputAction: TextInputAction.next,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? l.valRequired : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        JzTextField(label: l.roleLabel, controller: _role),
        const SizedBox(height: AppSpacing.lg),
        JzTextField(
          label: l.urlLabel,
          controller: _url,
          keyboardType: TextInputType.url,
        ),
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
