import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../domain/company.dart';
import 'widgets/video_player_view.dart';

/// Full-screen, swipeable viewer for gallery media. Images support pinch-zoom;
/// video items embed the [VideoPlayerView].
class GalleryViewerPage extends StatefulWidget {
  const GalleryViewerPage({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  final List<GalleryItem> items;
  final int initialIndex;

  @override
  State<GalleryViewerPage> createState() => _GalleryViewerPageState();
}

class _GalleryViewerPageState extends State<GalleryViewerPage> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.items[_index].caption;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_index + 1} / ${widget.items.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: widget.items.length,
              itemBuilder: (_, i) {
                final item = widget.items[i];
                if (item.isVideo) {
                  return Center(child: VideoPlayerView(url: item.mediaUrl));
                }
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: item.mediaUrl,
                      fit: BoxFit.contain,
                      placeholder: (_, _) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (caption != null && caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                caption,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
