import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/validators.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../../companies/domain/company.dart';
import '../../data/company_admin_repository.dart';

/// Manage the company's team / recruiters: list, add and remove.
class ManagePeoplePage extends ConsumerWidget {
  const ManagePeoplePage({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => const _AddPersonSheet(),
    );
    if (added == true) ref.invalidate(companyPeopleAdminProvider);
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, String id) async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.confirmRemoveTitle),
        content: Text(l.confirmRemovePersonBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.remove),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(companyAdminRepositoryProvider).removePerson(id);
      ref.invalidate(companyPeopleAdminProvider);
    } catch (e) {
      if (context.mounted) showErrorSnack(context, localizedError(context, e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final company = ref.watch(myCompanyProvider);
    final hasCompany = company.value != null;
    final async = ref.watch(companyPeopleAdminProvider);

    return Scaffold(
      floatingActionButton: hasCompany
          ? FloatingActionButton.extended(
              onPressed: () => _add(context, ref),
              backgroundColor: context.colors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(l.addPersonCta),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.managePeopleTitle),
            ),
            Expanded(
              child: company.isLoading
                  ? const JzLoader()
                  : !hasCompany
                  ? JzEmptyState(
                      icon: Icons.business_outlined,
                      title: l.noCompanyTitle,
                      message: l.noCompanyBody,
                    )
                  : async.when(
                      loading: () => const JzLoader(),
                      error: (_, _) => JzErrorState(
                        title: l.errorTitle,
                        message: l.errUnknown,
                        retryLabel: l.retry,
                        onRetry: () =>
                            ref.invalidate(companyPeopleAdminProvider),
                      ),
                      data: (people) {
                        if (people.isEmpty) {
                          return JzEmptyState(
                            icon: Icons.people_outline_rounded,
                            title: l.noPeopleTitle,
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            96,
                          ),
                          itemCount: people.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) => _PersonRow(
                            person: people[i],
                            onRemove: () => _remove(context, ref, people[i].id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person, required this.onRemove});
  final CompanyPerson person;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colors.surfaceVariant,
            child: Text(
              person.name.isEmpty
                  ? '?'
                  : person.name.substring(0, 1).toUpperCase(),
              style: context.text.titleSmall?.copyWith(color: colors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        person.name,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (person.isRecruiter) ...[
                      const SizedBox(width: AppSpacing.xs),
                      _RecruiterBadge(label: l.recruiterBadge),
                    ],
                  ],
                ),
                if (person.title != null && person.title!.isNotEmpty)
                  Text(
                    person.title!,
                    style: context.text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.l10n.remove,
            onPressed: onRemove,
            icon: Icon(Icons.delete_outline_rounded, color: colors.danger),
          ),
        ],
      ),
    );
  }
}

class _RecruiterBadge extends StatelessWidget {
  const _RecruiterBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AddPersonSheet extends ConsumerStatefulWidget {
  const _AddPersonSheet();

  @override
  ConsumerState<_AddPersonSheet> createState() => _AddPersonSheetState();
}

class _AddPersonSheetState extends ConsumerState<_AddPersonSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _title = TextEditingController();
  bool _isRecruiter = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(companyAdminRepositoryProvider)
          .addPerson(
            name: _name.text.trim(),
            title: _title.text.trim(),
            isRecruiter: _isRecruiter,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      // Without this, a failed write left the button spinning forever.
      if (mounted) showErrorSnack(context, localizedError(context, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.addPersonCta,
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            JzTextField(
              label: l.personNameLabel,
              controller: _name,
              validator: (v) => Validators.isNotBlank(v) ? null : l.valRequired,
            ),
            const SizedBox(height: AppSpacing.md),
            JzTextField(label: l.personTitleLabel, controller: _title),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.recruiterToggle, style: context.text.bodyLarge),
              value: _isRecruiter,
              onChanged: (v) => setState(() => _isRecruiter = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            JzPrimaryButton(label: l.add, loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
