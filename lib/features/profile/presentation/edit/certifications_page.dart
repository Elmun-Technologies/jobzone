import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../application/cv_providers.dart';
import '../../data/cv_repository.dart';
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
          // Whether the document itself is attached is the thing an employer
          // cares about, so it belongs on the card, not one tap deeper.
          if (e.hasFile) c.l10n.certificateAttached,
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
  bool _openingFile = false;

  /// The document already stored for this entry, if any.
  String? _filePath;
  int? _fileSize;
  String? _mimeType;

  /// A file chosen in this session. It is uploaded on Save, not on pick, so
  /// backing out of the editor can never leave an orphan in the bucket.
  Uint8List? _pickedBytes;
  String? _pickedName;
  String? _pickedMime;

  bool get _hasFile => _pickedBytes != null || (_filePath ?? '').isNotEmpty;

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
    _filePath = e?.filePath;
    _fileSize = e?.fileSize;
    _mimeType = e?.mimeType;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'heic'],
    );
    final file = result?.files.firstOrNull;
    if (file == null) return;
    // file_picker 12 reads bytes on demand — same as the résumé upload.
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pickedBytes = bytes;
      _pickedName = file.name;
      _pickedMime = _mimeFor(file.extension);
    });
  }

  /// Drops the attachment from the form. The stored object is deleted only
  /// once Save succeeds — until then nothing has changed on the server.
  void _removeFile() {
    setState(() {
      _pickedBytes = null;
      _pickedName = null;
      _pickedMime = null;
      _filePath = null;
      _fileSize = null;
      _mimeType = null;
    });
  }

  /// Opens the stored document. The bucket is private, so this asks for a
  /// short-lived signed URL rather than linking to a public path.
  Future<void> _openFile() async {
    final path = _filePath;
    if (path == null || path.isEmpty) return;
    setState(() => _openingFile = true);
    try {
      final url = await ref.read(cvRepositoryProvider).certificateFileUrl(path);
      if (!mounted) return;
      if (url == null ||
          !await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          )) {
        if (mounted) showErrorSnack(context, context.l10n.errUnknown);
      }
    } finally {
      if (mounted) setState(() => _openingFile = false);
    }
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
    final repo = ref.read(cvRepositoryProvider);
    try {
      var path = _filePath;
      var size = _fileSize;
      var mime = _mimeType;
      final picked = _pickedBytes;
      if (picked != null) {
        path = await repo.uploadCertificateFile(
          fileName: _pickedName!,
          bytes: picked,
          mimeType: _pickedMime!,
        );
        size = picked.length;
        mime = _pickedMime;
      }
      final entry = Certification(
        id: widget.existing?.id,
        name: _name.text.trim(),
        issuer: _nullable(_issuer.text),
        credentialId: _nullable(_credentialId.text),
        credentialUrl: _nullable(_credentialUrl.text),
        issuedDate: _issued,
        expiryDate: _expiry,
        filePath: path,
        fileSize: size,
        mimeType: mime,
      );
      await ref.read(certificationsControllerProvider.notifier).save(entry);
      // Only now is the old document unreferenced. Doing this before the save
      // would delete the file the row still points at if the save then failed.
      final previous = widget.existing?.filePath;
      if (previous != null && previous.isNotEmpty && previous != path) {
        await repo.removeCertificateFile(previous);
      }
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
        const SizedBox(height: AppSpacing.lg),
        _buildAttachment(context),
      ],
    );
  }

  /// The scan itself. Most qualifications in this market — a welding ticket, a
  /// forklift licence, a college diploma — have no issuer page to link to, so
  /// the document is the only proof there is.
  Widget _buildAttachment(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final pickedName = _pickedName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.certificateFileLabel, style: context.text.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l.certificateFileHint,
          style: context.text.bodySmall?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!_hasFile)
          OutlinedButton.icon(
            onPressed: _saving ? null : _pickFile,
            icon: const Icon(Icons.attach_file_rounded, size: 18),
            label: Text(l.certificateAttachCta),
          )
        else
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 20,
                      color: colors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        pickedName ?? l.certificateFileStored,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium,
                      ),
                    ),
                  ],
                ),
                if (pickedName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      l.certificateFileNotSavedYet,
                      style: context.text.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    // Viewing only makes sense for something already stored —
                    // a file picked a moment ago has no signed URL yet.
                    if (pickedName == null)
                      TextButton(
                        onPressed: _openingFile ? null : _openFile,
                        child: Text(l.certificateFileView),
                      ),
                    TextButton(
                      onPressed: _saving ? null : _pickFile,
                      child: Text(l.certificateFileReplace),
                    ),
                    TextButton(
                      onPressed: _saving ? null : _removeFile,
                      child: Text(l.certificateFileRemove),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

String? _nullable(String s) => s.trim().isEmpty ? null : s.trim();

/// file_picker gives an extension, Storage wants a content type. Anything
/// unexpected is stored as a generic binary rather than guessed at.
String _mimeFor(String? extension) => switch (extension?.toLowerCase()) {
  'pdf' => 'application/pdf',
  'jpg' || 'jpeg' => 'image/jpeg',
  'png' => 'image/png',
  'heic' => 'image/heic',
  _ => 'application/octet-stream',
};
