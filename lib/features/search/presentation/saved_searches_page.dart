import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/widgets/snackbars.dart';
import '../application/search_controller.dart';
import '../data/saved_searches_repository.dart';
import '../domain/saved_search.dart';
import '../domain/search_filters.dart';

/// Saved searches ("Obunalar"): stored search criteria the seeker can re-run.
/// Tapping one re-runs it on Search; the FAB opens a form to add one.
class SavedSearchesPage extends ConsumerWidget {
  const SavedSearchesPage({super.key});

  void _run(BuildContext context, WidgetRef ref, SavedSearch s) {
    ref
        .read(searchControllerProvider.notifier)
        .applyFilters(SearchFilters(query: s.keywords ?? '', city: s.city));
    context.push(Routes.search);
  }

  Future<void> _openCreate(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => const _CreateSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(savedSearchesControllerProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreate(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.savedSearches),
            ),
            Expanded(
              child: async.when(
                loading: () => const JzLoader(),
                error: (_, _) => JzErrorState(
                  title: l.errorTitle,
                  message: l.errUnknown,
                  retryLabel: l.retry,
                  onRetry: () =>
                      ref.invalidate(savedSearchesControllerProvider),
                ),
                data: (items) => items.isEmpty
                    ? _EmptySaved(onCreate: () => _openCreate(context))
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (_, i) => _SavedSearchCard(
                          item: items[i],
                          onTap: () => _run(context, ref, items[i]),
                          onDelete: () => ref
                              .read(savedSearchesControllerProvider.notifier)
                              .remove(items[i].id),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySaved extends StatelessWidget {
  const _EmptySaved({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return JzEmptyState(
      icon: Icons.notifications_none_rounded,
      title: l.savedSearchesEmptyTitle,
      message: l.savedSearchesEmptyBody,
      action: JzPrimaryButton(
        label: l.create,
        icon: Icons.add_rounded,
        onPressed: onCreate,
      ),
    );
  }
}

class _SavedSearchCard extends StatelessWidget {
  const _SavedSearchCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });
  final SavedSearch item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subtitle = [
      ?item.keywords,
      ?item.city,
    ].where((e) => e.isNotEmpty).join(' · ');

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.chipBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.delete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: colors.textSecondary,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom-sheet form to add a saved search (keywords + optional city).
class _CreateSheet extends ConsumerStatefulWidget {
  const _CreateSheet();

  @override
  ConsumerState<_CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends ConsumerState<_CreateSheet> {
  final _keywords = TextEditingController();
  final _city = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _keywords.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final kw = _keywords.text.trim();
    final city = _city.text.trim();
    final name = kw.isNotEmpty ? kw : city;
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(savedSearchesControllerProvider.notifier)
          .add(name: name, keywords: kw, city: city);
      if (mounted) {
        Navigator.of(context).pop();
        showInfoSnack(context, context.l10n.saved);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showErrorSnack(context, localizedError(context, e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl + inset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l.create,
            style: context.text.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _keywords,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l.savedSearchKeywords),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _city,
            decoration: InputDecoration(labelText: l.city),
          ),
          const SizedBox(height: AppSpacing.xl),
          JzPrimaryButton(label: l.save, loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
