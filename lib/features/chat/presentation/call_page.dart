import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../calls/application/call_providers.dart';
import '../../calls/domain/call_service.dart';
import '../domain/chat_models.dart';

/// Call screen (video or voice). Drives its UI from a [CallService] session
/// stream. The default service is simulated (no real transport); binding an
/// Agora/WebRTC service via `callServiceFactoryProvider` makes this real with
/// no changes here. See `docs/phase-8-realtime-and-push.md`.
class CallPage extends ConsumerStatefulWidget {
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
  ConsumerState<CallPage> createState() => _CallPageState();
}

class _CallPageState extends ConsumerState<CallPage> {
  late final CallService _service;
  StreamSubscription<CallSession>? _sub;
  CallSession _session = const CallSession();

  @override
  void initState() {
    super.initState();
    _service = ref.read(callServiceFactoryProvider)();
    _session = _service.current.copyWith(videoEnabled: widget.isVideo);
    _sub = _service.sessions.listen((s) {
      if (!mounted) return;
      setState(() => _session = s);
      if (s.phase == CallPhase.ended || s.phase == CallPhase.failed) {
        Navigator.of(context).maybePop();
      }
    });
    _service.join(
      channelId: widget.conversationId,
      type: widget.isVideo ? CallType.video : CallType.voice,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    // Tears down the engine/stream (a real service leaves the channel here).
    _service.dispose();
    super.dispose();
  }

  String get _durationText {
    final d = _session.duration;
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final peer = widget.peer;
    final name = peer?.title ?? l.navChat;
    final connecting = _session.phase == CallPhase.connecting;
    final status = connecting
        ? l.callConnecting
        : (widget.isVideo
              ? _durationText
              : '${l.callInProgress} · $_durationText');
    final showVideo = widget.isVideo && _session.videoEnabled;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (showVideo)
            _VideoBackdrop(url: peer?.avatarUrl)
          else
            const ColoredBox(color: Color(0xFF0E1116)),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xxl),
                _Avatar(url: peer?.avatarUrl, hidden: showVideo),
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
                  muted: _session.muted,
                  speaker: _session.speakerOn,
                  videoOn: _session.videoEnabled,
                  onToggleMute: () => _service.setMuted(!_session.muted),
                  onToggleSpeaker: () =>
                      _service.setSpeaker(!_session.speakerOn),
                  onToggleVideo: () =>
                      _service.setVideoEnabled(!_session.videoEnabled),
                  onEnd: () => _service.leave(),
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
