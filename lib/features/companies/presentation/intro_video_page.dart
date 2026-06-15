import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../localization/l10n_extension.dart';
import '../data/companies_repository.dart';
import 'widgets/video_player_view.dart';

/// Full-screen company intro video. The URL is taken from `extra` when
/// provided, otherwise resolved from the company record.
class IntroVideoPage extends ConsumerWidget {
  const IntroVideoPage({super.key, required this.companyId, this.videoUrl});

  final String companyId;
  final String? videoUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l.introVideoTitle),
      ),
      body: Center(child: _body(context, ref)),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref) {
    final direct = videoUrl;
    if (direct != null && direct.isNotEmpty) {
      return VideoPlayerView(url: direct);
    }
    final async = ref.watch(companyByIdProvider(companyId));
    return async.when(
      loading: () => const CircularProgressIndicator(color: Colors.white),
      error: (_, _) => Text(
        context.l10n.videoUnavailable,
        style: const TextStyle(color: Colors.white70),
      ),
      data: (company) {
        final url = company?.introVideoUrl;
        if (url == null || url.isEmpty) {
          return Text(
            context.l10n.videoUnavailable,
            style: const TextStyle(color: Colors.white70),
          );
        }
        return VideoPlayerView(url: url);
      },
    );
  }
}
