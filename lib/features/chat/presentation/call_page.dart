import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../domain/chat_models.dart';

/// UI-only call screen (video or voice). No real media transport yet — wiring
/// to WebRTC/Agora is deferred to a later phase. A local timer simulates the
/// in-call duration and the controls toggle local state only.
class CallPage extends StatefulWidget {
  const CallPage({
    super.key,
    required this.conversationId,
    required this.isVideo,
    this.peer,
  });

  final String conversationId;
  final bool isVideo;
  final Conversation? peer;

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _connecting = true;
  bool _muted = false;
  bool _speaker = true;
  bool _videoOn = true;

  @override
  void initState() {
    super.initState();
    // Simulate connecting → connected, then tick the call timer.
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _connecting = false);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _durationText {
    final m = _elapsed.inMinutes.toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final peer = widget.peer;
    final name = peer?.title ?? l.navChat;
    final status = _connecting
        ? l.callConnecting
        : (widget.isVideo
              ? _durationText
              : '${l.callInProgress} · $_durationText');

    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.isVideo && _videoOn)
            _VideoBackdrop(url: peer?.avatarUrl)
          else
            const ColoredBox(color: Color(0xFF0E1116)),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xxl),
                _Avatar(
                  url: peer?.avatarUrl,
                  hidden: widget.isVideo && _videoOn,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  name,
                  style: context.text.headlineSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  status,
                  style: context.text.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                _Controls(
                  isVideo: widget.isVideo,
                  muted: _muted,
                  speaker: _speaker,
                  videoOn: _videoOn,
                  onToggleMute: () => setState(() => _muted = !_muted),
                  onToggleSpeaker: () => setState(() => _speaker = !_speaker),
                  onToggleVideo: () => setState(() => _videoOn = !_videoOn),
                  onEnd: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoBackdrop extends StatelessWidget {
  const _VideoBackdrop({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const ColoredBox(color: Color(0xFF1F242D));
    }
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withValues(alpha: 0.35),
        BlendMode.darken,
      ),
      child: CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => const ColoredBox(color: Color(0xFF1F242D)),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url, this.hidden = false});
  final String? url;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    if (hidden) return const SizedBox(height: 120);
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.white24,
      backgroundImage: (url != null && url!.isNotEmpty)
          ? CachedNetworkImageProvider(url!)
          : null,
      child: (url == null || url!.isEmpty)
          ? const Icon(Icons.person_rounded, size: 60, color: Colors.white)
          : null,
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.isVideo,
    required this.muted,
    required this.speaker,
    required this.videoOn,
    required this.onToggleMute,
    required this.onToggleSpeaker,
    required this.onToggleVideo,
    required this.onEnd,
  });

  final bool isVideo;
  final bool muted;
  final bool speaker;
  final bool videoOn;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onToggleVideo;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleButton(
          icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
          active: muted,
          onTap: onToggleMute,
        ),
        const SizedBox(width: AppSpacing.lg),
        if (isVideo)
          _CircleButton(
            icon: videoOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
            active: !videoOn,
            onTap: onToggleVideo,
          )
        else
          _CircleButton(
            icon: speaker ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            active: !speaker,
            onTap: onToggleSpeaker,
          ),
        const SizedBox(width: AppSpacing.lg),
        _CircleButton(
          icon: Icons.call_end_rounded,
          background: const Color(0xFFDC2626),
          iconColor: Colors.white,
          onTap: onEnd,
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.background,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final Color? background;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final bg = background ?? (active ? Colors.white : Colors.white24);
    final fg = iconColor ?? (active ? Colors.black : Colors.white);
    return InkResponse(
      onTap: onTap,
      radius: 36,
      child: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: fg),
      ),
    );
  }
}
