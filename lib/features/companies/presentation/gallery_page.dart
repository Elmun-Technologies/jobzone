import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../data/companies_repository.dart';
import 'widgets/gallery_grid.dart';

/// Standalone "see all" gallery screen for a company.
class GalleryPage extends ConsumerWidget {
  const GalleryPage({super.key, required this.companyId});
  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(companyGalleryProvider(companyId));
    return JzScaffold(
      title: l.tabGallery,
      body: async.when(
        loading: () => const JzLoader(),
        error: (_, _) => JzErrorState(
          title: l.errorTitle,
          message: l.errUnknown,
          retryLabel: l.retry,
          onRetry: () => ref.invalidate(companyGalleryProvider(companyId)),
        ),
        data: (items) => items.isEmpty
            ? JzEmptyState(
                icon: Icons.photo_library_outlined,
                title: l.noGalleryTitle,
              )
            : GalleryGrid(
                items: items,
                padding: const EdgeInsets.all(AppSpacing.lg),
              ),
      ),
    );
  }
}
