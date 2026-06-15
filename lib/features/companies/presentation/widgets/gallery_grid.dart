import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/company.dart';
import '../gallery_viewer_page.dart';

/// Square-tile grid of gallery media. Tapping a tile opens a full-screen,
/// swipeable [GalleryViewerPage] at that index.
class GalleryGrid extends StatelessWidget {
  const GalleryGrid({
    super.key,
    required this.items,
    this.padding = EdgeInsets.zero,
  });

  final List<GalleryItem> items;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _GalleryTile(
        item: items[i],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GalleryViewerPage(items: items, initialIndex: i),
          ),
        ),
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.item, required this.onTap});
  final GalleryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: item.mediaUrl,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: colors.surfaceVariant),
              errorWidget: (_, _, _) => Container(
                color: colors.surfaceVariant,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: colors.textSecondary,
                ),
              ),
            ),
            if (item.isVideo)
              const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
