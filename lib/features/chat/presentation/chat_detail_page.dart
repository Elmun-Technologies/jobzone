import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/widgets/snackbars.dart';
import '../application/chat_providers.dart';
import '../data/chat_repository.dart';
import '../domain/chat_models.dart';
import 'util/chat_time.dart';

class ChatDetailPage extends ConsumerStatefulWidget {
  const ChatDetailPage({super.key, required this.conversationId, this.preview});

  final String conversationId;
  final Conversation? preview;

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  int? _lastMessageCount;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await ref.read(chatRepositoryProvider).markRead(widget.conversationId);
      } catch (_) {
        // Best-effort — a failed read receipt shouldn't disrupt the chat.
      }
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(conversationId: widget.conversationId, content: text);
    } catch (e) {
      if (!mounted) return;
      // Restore the text so a failed send never silently loses the message.
      _input.text = text;
      showErrorSnack(context, localizedError(context, e));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Conversation? get _convo =>
      widget.preview ??
      ref
          .read(chatRepositoryProvider)
          .offlineConversation(widget.conversationId);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final convo = _convo;
    final async = ref.watch(messagesProvider(widget.conversationId));

    return Scaffold(
      body: Column(
        children: [
          _Header(convo: convo),
          Expanded(
            child: async.when(
              loading: () => const JzLoader(),
              error: (_, _) => JzErrorState(
                title: l.errorTitle,
                message: l.errUnknown,
                retryLabel: l.retry,
                onRetry: () =>
                    ref.invalidate(messagesProvider(widget.conversationId)),
              ),
              data: (messages) {
                // Only auto-scroll on genuinely new messages (not every
                // rebuild/stream re-emit), and only when the user was already
                // near the bottom (or this is the first load) — otherwise a
                // new message while reading history yanks them back down.
                final isNewMessage =
                    _lastMessageCount == null ||
                    messages.length > _lastMessageCount!;
                final nearBottom =
                    !_scroll.hasClients ||
                    _scroll.position.maxScrollExtent - _scroll.position.pixels <
                        120;
                if (isNewMessage && (nearBottom || _lastMessageCount == null)) {
                  _scrollToBottom();
                }
                _lastMessageCount = messages.length;
                if (messages.isEmpty) {
                  return JzEmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: l.noMessagesTitle,
                    message: l.noMessagesBody,
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: messages.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) return const _DateChip();
                    return _MessageItem(
                      message: messages[i - 1],
                      peerName: convo?.title ?? '',
                      peerAvatar: convo?.avatarUrl,
                    );
                  },
                );
              },
            ),
          ),
          _Composer(controller: _input, onSend: _send),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.convo});
  final Conversation? convo;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topPad + AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          JzCircleButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: AppSpacing.md),
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white24,
            backgroundImage:
                (convo?.avatarUrl != null && convo!.avatarUrl!.isNotEmpty)
                ? CachedNetworkImageProvider(convo!.avatarUrl!)
                : null,
            child: (convo?.avatarUrl == null || convo!.avatarUrl!.isEmpty)
                ? const Icon(Icons.person_rounded, color: Colors.white)
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  convo?.title ?? l.navChat,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  l.online,
                  style: context.text.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Center(
        child: Text(
          context.l10n.today.toUpperCase(),
          style: context.text.labelSmall?.copyWith(
            color: context.colors.textSecondary,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class _MessageItem extends StatelessWidget {
  const _MessageItem({
    required this.message,
    required this.peerName,
    this.peerAvatar,
  });
  final Message message;
  final String peerName;
  final String? peerAvatar;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final mine = message.isMine;
    final maxW = MediaQuery.sizeOf(context).width * 0.72;

    final Widget bubble = switch (message.type) {
      'image' => _ImageBubble(url: message.attachmentUrl, maxWidth: maxW),
      'voice' || 'audio' => _VoiceBubble(mine: mine),
      _ => _TextBubble(text: message.content ?? '', mine: mine, maxWidth: maxW),
    };

    final meta = Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: mine
            ? [
                Text(
                  messageTime(context, message.createdAt),
                  style: context.text.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l.you,
                  style: context.text.labelSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]
            : [
                Flexible(
                  child: Text(
                    peerName,
                    style: context.text.labelSmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  messageTime(context, message.createdAt),
                  style: context.text.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
      ),
    );

    return Column(
      crossAxisAlignment: mine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: bubble,
        ),
        meta,
      ],
    );
  }
}

class _TextBubble extends StatelessWidget {
  const _TextBubble({
    required this.text,
    required this.mine,
    required this.maxWidth,
  });
  final String text;
  final bool mine;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: mine ? colors.primary : colors.surface,
        borderRadius: _bubbleRadius(mine),
        border: mine ? null : Border.all(color: colors.border),
      ),
      child: Text(
        text,
        style: context.text.bodyMedium?.copyWith(
          color: mine ? colors.onPrimary : colors.textPrimary,
        ),
      ),
    );
  }
}

class _ImageBubble extends StatelessWidget {
  const _ImageBubble({required this.url, required this.maxWidth});
  final String? url;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        width: maxWidth,
        height: maxWidth * 0.7,
        color: colors.surfaceVariant,
        child: (url == null || url!.isEmpty)
            ? null
            : CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover),
      ),
    );
  }
}

class _VoiceBubble extends StatelessWidget {
  const _VoiceBubble({required this.mine});
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = mine ? colors.onPrimary : colors.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: mine ? colors.primary : colors.surface,
        borderRadius: _bubbleRadius(mine),
        border: mine ? null : Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_circle_fill_rounded, color: fg, size: 30),
          const SizedBox(width: AppSpacing.sm),
          ..._waveform(fg),
          const SizedBox(width: AppSpacing.sm),
          Text('0:13', style: context.text.labelSmall?.copyWith(color: fg)),
        ],
      ),
    );
  }

  List<Widget> _waveform(Color color) {
    const heights = <double>[
      8,
      16,
      22,
      12,
      26,
      18,
      10,
      20,
      14,
      24,
      9,
      17,
      22,
      12,
    ];
    return [
      for (final h in heights)
        Container(
          width: 2.5,
          height: h,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
    ];
  }
}

BorderRadius _bubbleRadius(bool mine) => BorderRadius.only(
  topLeft: const Radius.circular(AppRadius.lg),
  topRight: const Radius.circular(AppRadius.lg),
  bottomLeft: Radius.circular(mine ? AppRadius.lg : AppRadius.xs),
  bottomRight: Radius.circular(mine ? AppRadius.xs : AppRadius.lg),
);

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            _RoundIcon(
              icon: Icons.add_rounded,
              onTap: () => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(l.comingSoon))),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(hintText: l.messageHint),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ListenableBuilder(
              listenable: controller,
              builder: (_, _) {
                final hasText = controller.text.trim().isNotEmpty;
                return _RoundIcon(
                  icon: hasText ? Icons.send_rounded : Icons.mic_rounded,
                  onTap: hasText
                      ? onSend
                      : () => ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(content: Text(l.comingSoon))),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.primary,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: colors.onPrimary),
        ),
      ),
    );
  }
}
