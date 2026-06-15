import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/chat/data/chat_repository.dart';
import 'package:jobzone/features/chat/domain/chat_models.dart';

void main() {
  late ProviderContainer container;
  late ChatRepository repo;

  setUp(() {
    container = ProviderContainer();
    repo = container.read(chatRepositoryProvider);
  });
  tearDown(() => container.dispose());

  test('offline conversations are seeded', () async {
    final convos = await repo.conversations();
    expect(convos, isNotEmpty);
    expect(convos.first.title, isNotEmpty);
  });

  test('messages stream seeds history and reflects a sent message', () async {
    const conv = 'conv-1';
    final stream = repo.messagesStream(conv);

    // History is delivered to a new listener.
    final initial = await stream.first;
    expect(initial, isNotEmpty);

    // Sending a message emits an updated list containing it (and marked mine).
    final sawSent = expectLater(
      stream,
      emitsThrough(
        predicate<List<Message>>(
          (msgs) => msgs.any((m) => m.content == 'Hello there' && m.isMine),
        ),
      ),
    );
    await repo.sendMessage(conversationId: conv, content: 'Hello there');
    await sawSent;
  });

  test('markRead clears the unread badge', () async {
    await repo.markRead('conv-1');
    final convos = await repo.conversations();
    final conv1 = convos.firstWhere((c) => c.id == 'conv-1');
    expect(conv1.unreadCount, 0);
  });
}
