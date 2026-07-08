import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chat_repository.dart';
import '../domain/chat_models.dart';

/// The signed-in user's conversations (most recent first).
final conversationsProvider = FutureProvider<List<Conversation>>(
  (ref) => ref.watch(chatRepositoryProvider).conversations(),
);

/// Real-time message stream for a single conversation. autoDispose so the
/// underlying Supabase realtime channel is torn down when the chat is closed
/// instead of leaking one live channel per conversation ever opened.
final messagesProvider = StreamProvider.autoDispose
    .family<List<Message>, String>(
      (ref, conversationId) =>
          ref.watch(chatRepositoryProvider).messagesStream(conversationId),
    );
