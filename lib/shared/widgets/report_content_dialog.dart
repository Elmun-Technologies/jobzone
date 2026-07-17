import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../design_system/design_system.dart';
import '../../localization/l10n_extension.dart';

/// Fixed enum of report reasons — must match the CHECK constraint on
/// public.content_reports.reason (0071_content_reports.sql).
const _reasons = <String>[
  'spam',
  'scam',
  'misleading',
  'discrimination',
  'illegal',
  'inappropriate',
  'personal_info',
  'other',
];

/// Opens the report dialog for a piece of user-generated content. Required
/// by Apple 1.2 (UGC apps must let users flag objectionable content). The
/// caller passes the target's type (job / company / review) + its id; the
/// dialog inserts into `content_reports`, which RLS gates to
/// `reporter_id = auth.uid()`.
Future<void> showReportContentDialog(
  BuildContext context, {
  required String targetType,
  required String targetId,
}) {
  return showDialog(
    context: context,
    builder: (_) => _ReportDialog(targetType: targetType, targetId: targetId),
  );
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog({required this.targetType, required this.targetId});
  final String targetType;
  final String targetId;

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String? _reason;
  final _details = TextEditingController();
  bool _submitting = false;
  bool _done = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l10n;
    if (_reason == null) return;
    setState(() => _submitting = true);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw StateError('no_session');
      await client.from('content_reports').insert({
        'reporter_id': userId,
        'target_type': widget.targetType,
        'target_id': widget.targetId,
        'reason': _reason,
        'details': _details.text.trim().isEmpty ? null : _details.text.trim(),
      });
      if (!mounted) return;
      setState(() => _done = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.reportError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (_done) {
      return AlertDialog(
        title: Text(l.reportSentTitle),
        content: Text(l.reportSentBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.close),
          ),
        ],
      );
    }
    return AlertDialog(
      title: Text(l.reportTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.reportSubtitle),
              const SizedBox(height: AppSpacing.md),
              ..._reasons.map(
                (r) => RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: r,
                  groupValue: _reason,
                  onChanged: (v) => setState(() => _reason = v),
                  title: Text(_reasonLabel(l, r)),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _details,
                maxLength: 500,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l.reportDetailsLabel,
                  hintText: l.reportDetailsHint,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: (_reason == null || _submitting) ? null : _submit,
          child: Text(_submitting ? l.reportSending : l.reportSubmit),
        ),
      ],
    );
  }

  String _reasonLabel(dynamic l, String reason) {
    switch (reason) {
      case 'spam':
        return l.reportReasonSpam;
      case 'scam':
        return l.reportReasonScam;
      case 'misleading':
        return l.reportReasonMisleading;
      case 'discrimination':
        return l.reportReasonDiscrimination;
      case 'illegal':
        return l.reportReasonIllegal;
      case 'inappropriate':
        return l.reportReasonInappropriate;
      case 'personal_info':
        return l.reportReasonPersonalInfo;
      default:
        return l.reportReasonOther;
    }
  }
}
