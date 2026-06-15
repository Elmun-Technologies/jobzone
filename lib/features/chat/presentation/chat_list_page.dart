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

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(conversationsProvider);
    return JzScaffold(
      title: l.navChat,
      showBack: false,
      body: async.when(
        loading: () => const TileListSkeleton(),
        error: (_, _) => JzErrorState(
          title: l.errorTitle,
          message: l.errUnknown,
          retryLabel: l.retry,
          onRetry: () => ref.invalidate(conversationsProvider),
        ),
        data: (convos) => convos.isEmpty
            ? JzEmptyState(
                icon: Icons.chat_bubble_outline_rounded,
                title: l.noChatsTitle,
                message: l.noChatsBody,
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(conversationsProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: convos.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    indent: 84,
                    color: context.colors.border,
                  ),
                  itemBuilder: (_, i) => _ConversationTile(convo: convos[i]),
                ),
              ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.convo});
  final Conversation convo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasUnread = convo.unreadCount > 0;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      onTap: () => context.push(Routes.chatDetail(convo.id), extra: convo),
      leading: _Avatar(url: convo.avatarUrl),
      title: Text(
        convo.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.text.titleSmall,
      ),
      subtitle: convo.lastMessage == null
          ? null
          : Text(
              convo.lastMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(
                color: hasUnread ? colors.textPrimary : colors.textSecondary,
                fontWeight: hasUnread ? FontWeight.w600 : null,
              ),
            ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (convo.lastMessageAt != null)
            Text(
              chatListTime(convo.lastMessageAt!),
              style: context.text.labelSmall?.copyWith(
                color: hasUnread ? colors.primary : colors.textSecondary,
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Text(
                '${convo.unreadCount}',
                textAlign: TextAlign.center,
                style: context.text.labelSmall?.copyWith(
                  color: colors.onPrimary,
                  height: 1,
                ),
              ),
            )
          else
            const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return CircleAvatar(
      radius: 26,
      backgroundColor: colors.chipBackground,
      backgroundImage: (url != null && url!.isNotEmpty)
          ? CachedNetworkImageProvider(url!)
          : null,
      child: (url == null || url!.isEmpty)
          ? Icon(Icons.person_rounded, color: colors.primary)
          : null,
    );
  }
}
