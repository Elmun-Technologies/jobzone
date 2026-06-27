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

class CertificationsListPage extends ConsumerWidget {
  const CertificationsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(certificationsControllerProvider);
    return CvSectionScaffold<Certification>(
      title: l.sectionCertifications,
      async: async,
      emptyTitle: l.noEntriesYet,
      emptyBody: l.certificationsEmptyBody,
      emptyIcon: Icons.verified_outlined,
      onAdd: () => _openEditor(context),
      itemBuilder: (c, e) => CvEntryCard(
        title: e.name,
        subtitle: [
          e.issuer,
          if (e.issuedDate != null) periodText(c, e.issuedDate, null),
        ].where((s) => s != null && s.isNotEmpty).join(' • '),
        onTap: () => _openEditor(context, e),
      ),
    );
  }

  void _openEditor(BuildContext context, [Certification? existing]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CertificationEditPage(existing: existing),
      ),
    );
  }
}

class CertificationEditPage extends ConsumerStatefulWidget {
  const CertificationEditPage({super.key, this.existing});
  final Certification? existing;

  @override
  ConsumerState<CertificationEditPage> createState() =>
      _CertificationEditPageState();
}

class _CertificationEditPageState extends ConsumerState<CertificationEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _issuer;
  late final TextEditingController _credentialId;
  late final TextEditingController _credentialUrl;
  DateTime? _issued;
  DateTime? _expiry;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name);
    _issuer = TextEditingController(text: e?.issuer);
    _credentialId = TextEditingController(text: e?.credentialId);
    _credentialUrl = TextEditingController(text: e?.credentialUrl);
    _issued = e?.issuedDate;
    _expiry = e?.expiryDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _issuer.dispose();
    _credentialId.dispose();
    _credentialUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final entry = Certification(
      id: widget.existing?.id,
      name: _name.text.trim(),
      issuer: _nullable(_issuer.text),
      credentialId: _nullable(_credentialId.text),
      credentialUrl: _nullable(_credentialUrl.text),
      issuedDate: _issued,
      expiryDate: _expiry,
    );
    try {
      await ref.read(certificationsControllerProvider.notifier).save(entry);
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
      await ref.read(certificationsControllerProvider.notifier).remove(id);
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
      title: widget.existing == null ? l.addCertification : l.editCertification,
      formKey: _formKey,
      saving: _saving,
      onSave: _save,
      onDelete: widget.existing == null ? null : _delete,
      children: [
        JzTextField(
          label: l.certificationNameLabel,
          controller: _name,
          textInputAction: TextInputAction.next,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? l.valRequired : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        JzTextField(label: l.issuerLabel, controller: _issuer),
        const SizedBox(height: AppSpacing.lg),
        JzTextField(label: l.credentialIdLabel, controller: _credentialId),
        const SizedBox(height: AppSpacing.lg),
        JzTextField(
          label: l.credentialUrlLabel,
          controller: _credentialUrl,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: AppSpacing.lg),
        DateField(
          label: l.issuedDate,
          value: _issued,
          onChanged: (d) => setState(() => _issued = d),
        ),
        const SizedBox(height: AppSpacing.lg),
        DateField(
          label: l.expiryDate,
          value: _expiry,
          onChanged: (d) => setState(() => _expiry = d),
        ),
      ],
    );
  }
}

String? _nullable(String s) => s.trim().isEmpty ? null : s.trim();
