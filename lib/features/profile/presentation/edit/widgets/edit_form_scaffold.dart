import 'package:flutter/material.dart';

import '../../../../../design_system/design_system.dart';
import '../../../../../localization/l10n_extension.dart';

/// Standard layout for a CV edit form: scrollable body with a pinned Save
/// button, an optional Delete action in the app bar, and a busy state.
class EditFormScaffold extends StatelessWidget {
  const EditFormScaffold({
    super.key,
    required this.title,
    required this.children,
    required this.onSave,
    this.onDelete,
    this.saving = false,
    this.formKey,
  });

  final String title;
  final List<Widget> children;
  final Future<void> Function() onSave;
  final Future<void> Function()? onDelete;
  final bool saving;
  final GlobalKey<FormState>? formKey;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return JzScaffold(
      title: title,
      actions: [
        if (onDelete != null)
          IconButton(
            tooltip: l.delete,
            onPressed: saving ? null : () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
      ],
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: children,
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
              child: JzPrimaryButton(
                label: l.save,
                loading: saving,
                onPressed: () => onSave(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.deleteEntryTitle),
        content: Text(l.deleteEntryBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok == true) await onDelete!();
  }
}
