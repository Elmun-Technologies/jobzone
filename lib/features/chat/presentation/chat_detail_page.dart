import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
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

  @override
  void initState() {
    super.initState();
    // Clear the unread badge once opened.
    Future.microtask(
      () => ref.read(chatRepositoryProvider).markRead(widget.conversationId),
    );
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
    await ref
        .read(chatRepositoryProvider)
        .sendMessage(conversationId: widget.conversationId, content: text);
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
    final colors = context.colors;
    final convo = _convo;
    final async = ref.watch(messagesProvider(widget.conversationId));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colors.chipBackground,
              backgroundImage:
                  (convo?.avatarUrl != null && convo!.avatarUrl!.isNotEmpty)
                  ? CachedNetworkImageProvider(convo.avatarUrl!)
                  : null,
              child: (convo?.avatarUrl == null || convo!.avatarUrl!.isEmpty)
                  ? Icon(Icons.person_rounded, size: 20, color: colors.primary)
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    convo?.title ?? l.navChat,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall,
                  ),
                  if (convo?.subtitle != null)
                    Text(
                      convo!.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l.voiceCall,
            icon: const Icon(Icons.call_outlined),
            onPressed: () => context.push(
              Routes.voiceCall(widget.conversationId),
              extra: convo,
            ),
          ),
          IconButton(
            tooltip: l.videoCall,
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () => context.push(
              Routes.videoCall(widget.conversationId),
              extra: convo,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: async.when(
              loading: () => const JzLoader(),
              error: (_, _) => Center(child: Text(l.errUnknown)),
              data: (messages) {
                _scrollToBottom();
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
                  itemCount: messages.length,
                  itemBuilder: (_, i) => _Bubble(message: messages[i]),
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final Message message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final mine = message.isMine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.74,
        ),
        decoration: BoxDecoration(
          color: mine ? colors.primary : colors.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(mine ? AppRadius.lg : AppRadius.xs),
            bottomRight: Radius.circular(mine ? AppRadius.xs : AppRadius.lg),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.content != null)
              Text(
                message.content!,
                style: context.text.bodyMedium?.copyWith(
                  color: mine ? colors.onPrimary : colors.textPrimary,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              messageTime(context, message.createdAt),
              style: context.text.labelSmall?.copyWith(
                color: mine
                    ? colors.onPrimary.withValues(alpha: 0.7)
                    : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
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
            IconButton.filled(
              onPressed: onSend,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
