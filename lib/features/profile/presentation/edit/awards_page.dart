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

class AwardsListPage extends ConsumerWidget {
  const AwardsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(awardsControllerProvider);
    return CvSectionScaffold<Award>(
      title: l.sectionAwards,
      async: async,
      emptyTitle: l.noEntriesYet,
      emptyBody: l.awardsEmptyBody,
      emptyIcon: Icons.emoji_events_outlined,
      onAdd: () => _openEditor(context),
      itemBuilder: (c, e) => CvEntryCard(
        title: e.title,
        subtitle: [
          e.issuer,
          if (e.date != null) periodText(c, e.date, null),
        ].where((s) => s != null && s.isNotEmpty).join(' • '),
        detail: e.description,
        onTap: () => _openEditor(context, e),
      ),
    );
  }

  void _openEditor(BuildContext context, [Award? existing]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AwardEditPage(existing: existing)),
    );
  }
}

class AwardEditPage extends ConsumerStatefulWidget {
  const AwardEditPage({super.key, this.existing});
  final Award? existing;

  @override
  ConsumerState<AwardEditPage> createState() => _AwardEditPageState();
}

class _AwardEditPageState extends ConsumerState<AwardEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _issuer;
  late final TextEditingController _description;
  DateTime? _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title);
    _issuer = TextEditingController(text: e?.issuer);
    _description = TextEditingController(text: e?.description);
    _date = e?.date;
  }

  @override
  void dispose() {
    _title.dispose();
    _issuer.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final entry = Award(
      id: widget.existing?.id,
      title: _title.text.trim(),
      issuer: _nullable(_issuer.text),
      date: _date,
      description: _nullable(_description.text),
    );
    try {
      await ref.read(awardsControllerProvider.notifier).save(entry);
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
      await ref.read(awardsControllerProvider.notifier).remove(id);
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
      title: widget.existing == null ? l.addAward : l.editAward,
      formKey: _formKey,
      saving: _saving,
      onSave: _save,
      onDelete: widget.existing == null ? null : _delete,
      children: [
        JzTextField(
          label: l.awardTitleLabel,
          controller: _title,
          textInputAction: TextInputAction.next,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? l.valRequired : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        JzTextField(label: l.issuerLabel, controller: _issuer),
        const SizedBox(height: AppSpacing.lg),
        DateField(
          label: l.dateLabel,
          value: _date,
          onChanged: (d) => setState(() => _date = d),
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
