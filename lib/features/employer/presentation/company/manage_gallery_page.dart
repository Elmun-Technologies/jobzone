import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/validators.dart';
import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../shared/widgets/snackbars.dart';
import '../../../companies/domain/company.dart';
import '../../data/company_admin_repository.dart';

/// Manage the company gallery: a grid of images with add / remove.
class ManageGalleryPage extends ConsumerWidget {
  const ManageGalleryPage({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => const _AddGallerySheet(),
    );
    if (added == true) ref.invalidate(companyGalleryAdminProvider);
  }

  Future<void> _remove(WidgetRef ref, String id) async {
    await ref.read(companyAdminRepositoryProvider).removeGalleryItem(id);
    ref.invalidate(companyGalleryAdminProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(companyGalleryAdminProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        backgroundColor: context.colors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: Text(l.addPhotoCta),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.manageGalleryTitle),
            ),
            Expanded(
              child: async.when(
                loading: () => const JzLoader(),
                error: (_, _) => JzErrorState(
                  title: l.errorTitle,
                  message: l.errUnknown,
                  retryLabel: l.retry,
                  onRetry: () => ref.invalidate(companyGalleryAdminProvider),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return JzEmptyState(
                      icon: Icons.photo_library_outlined,
                      title: l.noGalleryTitle,
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      96,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                        ),
                    itemCount: items.length,
                    itemBuilder: (context, i) => _GalleryTile(
                      item: items[i],
                      onRemove: () => _remove(ref, items[i].id),
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

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.item, required this.onRemove});
  final GalleryItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: item.mediaUrl,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => ColoredBox(
              color: colors.surfaceVariant,
              child: Icon(
                Icons.broken_image_outlined,
                color: colors.textSecondary,
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.xs,
            right: AppSpacing.xs,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddGallerySheet extends ConsumerStatefulWidget {
  const _AddGallerySheet();

  @override
  ConsumerState<_AddGallerySheet> createState() => _AddGallerySheetState();
}

class _AddGallerySheetState extends ConsumerState<_AddGallerySheet> {
  final _formKey = GlobalKey<FormState>();
  final _url = TextEditingController();
  final _caption = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _url.dispose();
    _caption.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(companyAdminRepositoryProvider)
          .addGalleryItem(
            mediaUrl: _url.text.trim(),
            caption: _caption.text.trim(),
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
              l.addPhotoCta,
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            JzTextField(
              label: l.imageUrlLabel,
              controller: _url,
              keyboardType: TextInputType.url,
              validator: (v) => Validators.isNotBlank(v) ? null : l.valRequired,
            ),
            const SizedBox(height: AppSpacing.md),
            JzTextField(label: l.captionLabel, controller: _caption),
            const SizedBox(height: AppSpacing.lg),
            JzPrimaryButton(label: l.add, loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
