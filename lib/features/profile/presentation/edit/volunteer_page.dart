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

class VolunteerListPage extends ConsumerWidget {
  const VolunteerListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(volunteerControllerProvider);
    return CvSectionScaffold<Volunteer>(
      title: l.sectionVolunteer,
      async: async,
      emptyTitle: l.noEntriesYet,
      emptyBody: l.volunteerEmptyBody,
      emptyIcon: Icons.volunteer_activism_outlined,
      onAdd: () => _openEditor(context),
      itemBuilder: (c, e) => CvEntryCard(
        title: e.organization,
        subtitle: [
          e.role,
          e.cause,
          periodText(c, e.startDate, e.endDate),
        ].where((s) => s != null && s.isNotEmpty).join(' • '),
        detail: e.description,
        onTap: () => _openEditor(context, e),
      ),
    );
  }

  void _openEditor(BuildContext context, [Volunteer? existing]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VolunteerEditPage(existing: existing)),
    );
  }
}

class VolunteerEditPage extends ConsumerStatefulWidget {
  const VolunteerEditPage({super.key, this.existing});
  final Volunteer? existing;

  @override
  ConsumerState<VolunteerEditPage> createState() => _VolunteerEditPageState();
}

class _VolunteerEditPageState extends ConsumerState<VolunteerEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _org;
  late final TextEditingController _role;
  late final TextEditingController _cause;
  late final TextEditingController _description;
  DateTime? _start;
  DateTime? _end;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _org = TextEditingController(text: e?.organization);
    _role = TextEditingController(text: e?.role);
    _cause = TextEditingController(text: e?.cause);
    _description = TextEditingController(text: e?.description);
    _start = e?.startDate;
    _end = e?.endDate;
  }

  @override
  void dispose() {
    _org.dispose();
    _role.dispose();
    _cause.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final entry = Volunteer(
      id: widget.existing?.id,
      organization: _org.text.trim(),
      role: _nullable(_role.text),
      cause: _nullable(_cause.text),
      startDate: _start,
      endDate: _end,
      description: _nullable(_description.text),
    );
    try {
      await ref.read(volunteerControllerProvider.notifier).save(entry);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, localizedError(context, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final id = widget.existing?.id;
    if (id == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(volunteerControllerProvider.notifier).remove(id);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, localizedError(context, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return EditFormScaffold(
      title: widget.existing == null ? l.addVolunteer : l.editVolunteer,
      formKey: _formKey,
      saving: _saving,
      onSave: _save,
      onDelete: widget.existing == null ? null : _delete,
      children: [
        JzTextField(
          label: l.organizationLabel,
          controller: _org,
          textInputAction: TextInputAction.next,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? l.valRequired : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        JzTextField(label: l.roleLabel, controller: _role),
        const SizedBox(height: AppSpacing.lg),
        JzTextField(label: l.causeLabel, controller: _cause),
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
