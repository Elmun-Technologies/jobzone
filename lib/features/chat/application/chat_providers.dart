import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chat_repository.dart';
import '../domain/chat_models.dart';

/// The signed-in user's conversations (most recent first).
final conversationsProvider = FutureProvider<List<Conversation>>(
  (ref) => ref.watch(chatRepositoryProvider).conversations(),
);

/// Real-time message stream for a single conversation.
final messagesProvider = StreamProvider.family<List<Message>, String>(
  (ref, conversationId) =>
      ref.watch(chatRepositoryProvider).messagesStream(conversationId),
);
