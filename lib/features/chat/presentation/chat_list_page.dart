import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../application/chat_providers.dart';
import '../domain/chat_models.dart';
import 'util/chat_time.dart';

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key});

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final async = ref.watch(conversationsProvider);
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              topPad + AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                Text(
                  l.navChat,
                  style: context.text.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: colors.textSecondary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _query = v),
                          decoration: InputDecoration(
                            hintText: l.search,
                            border: InputBorder.none,
                            filled: false,
                            isCollapsed: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const TileListSkeleton(),
              error: (_, _) => JzErrorState(
                title: l.errorTitle,
                message: l.errUnknown,
                retryLabel: l.retry,
                onRetry: () => ref.invalidate(conversationsProvider),
              ),
              data: (convos) {
                final q = _query.trim().toLowerCase();
                final filtered = q.isEmpty
                    ? convos
                    : convos
                          .where((c) => c.title.toLowerCase().contains(q))
                          .toList();
                if (filtered.isEmpty) {
                  return JzEmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: l.noChatsTitle,
                    message: l.noChatsBody,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(conversationsProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) =>
                        _ConversationCard(convo: filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({required this.convo});
  final Conversation convo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasUnread = convo.unreadCount > 0;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.push(Routes.chatDetail(convo.id), extra: convo),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              _Avatar(url: convo.avatarUrl, online: !hasUnread),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      convo.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (convo.lastMessage != null)
                      Text(
                        convo.lastMessage!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: hasUnread
                              ? colors.textPrimary
                              : colors.textSecondary,
                          fontWeight: hasUnread ? FontWeight.w600 : null,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (convo.lastMessageAt != null)
                    Text(
                      chatListTime(context, convo.lastMessageAt!),
                      style: context.text.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  if (hasUnread) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.all(5),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${convo.unreadCount}',
                        textAlign: TextAlign.center,
                        style: context.text.labelSmall?.copyWith(
                          color: colors.onPrimary,
                          height: 1,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url, this.online = false});
  final String? url;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: colors.surfaceVariant,
            backgroundImage: (url != null && url!.isNotEmpty)
                ? CachedNetworkImageProvider(url!)
                : null,
            child: (url == null || url!.isEmpty)
                ? Icon(Icons.person_rounded, color: colors.textSecondary)
                : null,
          ),
          if (online)
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
