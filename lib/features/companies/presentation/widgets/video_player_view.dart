import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';

/// Network video player (video_player + chewie) with init / loading / error
/// handling. Used by the intro-video page and the gallery viewer.
class VideoPlayerView extends StatefulWidget {
  const VideoPlayerView({
    super.key,
    required this.url,
    this.autoPlay = true,
    this.aspectRatio,
  });

  final String url;
  final bool autoPlay;
  final double? aspectRatio;

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final video = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _video = video;
    try {
      await video.initialize();
      if (!mounted) return;
      setState(() {
        _chewie = ChewieController(
          videoPlayerController: video,
          autoPlay: widget.autoPlay,
          looping: false,
          aspectRatio: widget.aspectRatio ?? video.value.aspectRatio,
          allowFullScreen: true,
        );
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            context.l10n.videoUnavailable,
            style: context.text.bodyMedium?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final chewie = _chewie;
    if (chewie == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return AspectRatio(
      aspectRatio: chewie.aspectRatio ?? 16 / 9,
      child: Chewie(controller: chewie),
    );
  }
}
