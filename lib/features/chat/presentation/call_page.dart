import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../calls/application/call_providers.dart';
import '../../calls/domain/call_service.dart';
import '../domain/chat_models.dart';

/// Call screen (video or voice), matching the Figma design. Drives its UI from
/// a [CallService] session stream (default = simulated; an Agora/WebRTC service
/// drops in via `callServiceFactoryProvider`). See
/// `docs/phase-8-realtime-and-push.md`.
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
    final colors = context.colors;
    final peer = widget.peer;
    final name = peer?.title ?? l.navChat;
    final connecting = _session.phase == CallPhase.connecting;
    final status = connecting ? l.callConnecting : _durationText;

    return Scaffold(
      backgroundColor: colors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            if (widget.isVideo) ...[
              const Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.lg,
                child: _LiveBadge(),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.lg,
                child: _SelfPreview(url: peer?.avatarUrl),
              ),
              Positioned(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                bottom: 150,
                child: _NameTime(name: name, status: status, center: false),
              ),
            ] else
              Align(
                alignment: const Alignment(0, -0.15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _BigAvatar(url: peer?.avatarUrl),
                    const SizedBox(height: AppSpacing.xl),
                    _NameTime(name: name, status: status, center: true),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: _Controls(
                  muted: _session.muted,
                  speaker: _session.speakerOn,
                  videoOn: _session.videoEnabled,
                  onToggleSpeaker: () =>
                      _service.setSpeaker(!_session.speakerOn),
                  onToggleMute: () => _service.setMuted(!_session.muted),
                  onToggleVideo: () =>
                      _service.setVideoEnabled(!_session.videoEnabled),
                  onChat: () => Navigator.of(context).maybePop(),
                  onEnd: () => _service.leave(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NameTime extends StatelessWidget {
  const _NameTime({
    required this.name,
    required this.status,
    required this.center,
  });
  final String name;
  final String status;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: context.text.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          status,
          style: context.text.bodyLarge?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            context.l10n.callLive,
            style: context.text.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelfPreview extends StatelessWidget {
  const _SelfPreview({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 96,
        height: 132,
        color: const Color(0xFFCDCDD6),
        child: (url == null || url!.isEmpty)
            ? null
            : CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover),
      ),
    );
  }
}

class _BigAvatar extends StatelessWidget {
  const _BigAvatar({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        width: 150,
        height: 180,
        color: const Color(0xFFCDCDD6),
        child: (url == null || url!.isEmpty)
            ? const Icon(Icons.person_rounded, size: 80, color: Colors.white)
            : CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.muted,
    required this.speaker,
    required this.videoOn,
    required this.onToggleSpeaker,
    required this.onToggleMute,
    required this.onToggleVideo,
    required this.onChat,
    required this.onEnd,
  });

  final bool muted;
  final bool speaker;
  final bool videoOn;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleVideo;
  final VoidCallback onChat;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Ctrl(
          icon: speaker ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          onTap: onToggleSpeaker,
        ),
        const SizedBox(width: AppSpacing.lg),
        _Ctrl(
          icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
          onTap: onToggleMute,
        ),
        const SizedBox(width: AppSpacing.lg),
        _EndButton(onTap: onEnd),
        const SizedBox(width: AppSpacing.lg),
        _Ctrl(
          icon: videoOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
          onTap: onToggleVideo,
        ),
        const SizedBox(width: AppSpacing.lg),
        _Ctrl(icon: Icons.chat_bubble_rounded, onTap: onChat),
      ],
    );
  }
}

class _Ctrl extends StatelessWidget {
  const _Ctrl({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _EndButton extends StatelessWidget {
  const _EndButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEF4444),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 64,
          height: 64,
          child: Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
