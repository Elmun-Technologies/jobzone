import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/chat_models.dart';

/// Sentinel id for "me" in offline mode (no auth user available).
const kOfflineMeId = 'me';

/// Reads conversations and streams messages in real time. Online this uses
/// Supabase Postgres Changes (`.stream()`); offline it uses an in-memory store
/// with a broadcast stream per conversation (and a canned auto-reply) so the
/// chat is demoable without a backend.
class ChatRepository {
  ChatRepository(this._ref);

  final Ref _ref;

  bool get _online => Env.hasSupabase;
  String? get _uid => _ref.read(supabaseClientProvider).auth.currentUser?.id;

  Future<List<Conversation>> conversations() async {
    if (!_online) return _offline.conversations();
    final uid = _uid;
    if (uid == null) return const [];
    // Conversations the user participates in, most recent first. Display fields
    // for the other participant are resolved per row.
    final rows = await _ref
        .read(supabaseClientProvider)
        .from('conversation_participants')
        .select('conversation_id, conversations!inner(last_message_at)')
        .eq('profile_id', uid);
    final ids = (rows as List)
        .map((e) => (e as Map)['conversation_id'] as String)
        .toList();
    final result = <Conversation>[];
    for (final id in ids) {
      result.add(await _resolveConversation(id, uid));
    }
    result.sort((a, b) {
      final ax = a.lastMessageAt;
      final bx = b.lastMessageAt;
      if (ax == null && bx == null) return 0;
      if (ax == null) return 1;
      if (bx == null) return -1;
      return bx.compareTo(ax);
    });
    return result;
  }

  Future<Conversation> _resolveConversation(String id, String uid) async {
    final client = _ref.read(supabaseClientProvider);
    final other = await client
        .from('conversation_participants')
        .select('profiles_public(full_name, avatar_url, headline)')
        .eq('conversation_id', id)
        .neq('profile_id', uid)
        .limit(1)
        .maybeSingle();
    final profile = other?['profiles_public'] as Map<String, dynamic>?;
    // This participant's own last_read_at drives the unread count below.
    final mine = await client
        .from('conversation_participants')
        .select('last_read_at')
        .eq('conversation_id', id)
        .eq('profile_id', uid)
        .maybeSingle();
    final lastReadAt = DateTime.tryParse('${mine?['last_read_at']}');
    final convo = await client
        .from('conversations')
        .select('last_message_at, messages(content, created_at, sender_id)')
        .eq('id', id)
        .maybeSingle();
    String? lastText;
    DateTime? lastAt;
    var unread = 0;
    final msgs = convo?['messages'];
    if (msgs is List && msgs.isNotEmpty) {
      msgs.sort((a, b) => '${b['created_at']}'.compareTo('${a['created_at']}'));
      lastText = msgs.first['content'] as String?;
      lastAt = DateTime.tryParse('${msgs.first['created_at']}')?.toLocal();
      for (final m in msgs) {
        if (m['sender_id'] == uid) continue;
        final createdAt = DateTime.tryParse('${m['created_at']}');
        if (createdAt == null) continue;
        if (lastReadAt == null || createdAt.isAfter(lastReadAt)) unread++;
      }
    }
    return Conversation(
      id: id,
      title: (profile?['full_name'] as String?) ?? 'Conversation',
      avatarUrl: profile?['avatar_url'] as String?,
      subtitle: profile?['headline'] as String?,
      lastMessage: lastText,
      lastMessageAt: lastAt,
      unreadCount: unread,
    );
  }

  Stream<List<Message>> messagesStream(String conversationId) {
    if (!_online) return _offline.stream(conversationId);
    final uid = _uid;
    return _ref
        .read(supabaseClientProvider)
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((rows) => rows.map((r) => Message.fromMap(r, uid)).toList());
  }

  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final text = content.trim();
    if (text.isEmpty) return;
    if (!_online) {
      _offline.send(conversationId, text);
      return;
    }
    final uid = _uid;
    if (uid == null) return;
    await _ref.read(supabaseClientProvider).from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': uid,
      'content': text,
    });
  }

  Future<void> markRead(String conversationId) async {
    if (!_online) {
      _offline.markRead(conversationId);
      return;
    }
    final uid = _uid;
    if (uid == null) return;
    await _ref
        .read(supabaseClientProvider)
        .from('conversation_participants')
        .update({'last_read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('conversation_id', conversationId)
        .eq('profile_id', uid);
  }

  Conversation? offlineConversation(String id) =>
      _online ? null : _offline.byId(id);

  /// Returns a REAL direct-conversation id between the current user and
  /// [otherProfileId], creating one if needed. Online this calls the
  /// `get_or_create_direct_conversation` security-definer RPC (migration 0065)
  /// so the conversation + both participant rows exist before the chat opens —
  /// without it the first send fails the FK/RLS check. Offline it returns a
  /// deterministic id so the mock chat still opens (an empty on-demand thread).
  Future<String> getOrCreateDirectConversation(String otherProfileId) async {
    if (!_online) return 'direct-$otherProfileId';
    final id = await _ref
        .read(supabaseClientProvider)
        .rpc(
          'get_or_create_direct_conversation',
          params: {'p_other': otherProfileId},
        );
    return id as String;
  }
}

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref),
);

// --- Offline in-memory chat --------------------------------------------------
class _OfflineChat {
  int _seq = 0;
  final _controllers = <String, StreamController<List<Message>>>{};

  final _convos = <Conversation>[
    Conversation(
      id: 'conv-1',
      title: 'Dilnoza Yusupova',
      subtitle: 'Head of Talent · Acme',
      avatarUrl: 'https://picsum.photos/seed/p1/200/200',
      lastMessage: 'Looking forward to our chat!',
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 12)),
      unreadCount: 1,
    ),
    Conversation(
      id: 'conv-2',
      title: 'Kamila Rashidova',
      subtitle: 'Design Lead · Nimbus',
      avatarUrl: 'https://picsum.photos/seed/p3/200/200',
      lastMessage: 'Thanks for applying 🙌',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  late final Map<String, List<Message>> _messages = {
    'conv-1': [
      _msg(
        'conv-1',
        'p1',
        'Hi! Thanks for your interest in the role.',
        const Duration(minutes: 30),
      ),
      _msg(
        'conv-1',
        kOfflineMeId,
        'Hello! Happy to learn more.',
        const Duration(minutes: 20),
      ),
      _msg(
        'conv-1',
        'p1',
        'Looking forward to our chat!',
        const Duration(minutes: 12),
      ),
    ],
    'conv-2': [
      _msg('conv-2', 'p3', 'Thanks for applying 🙌', const Duration(hours: 3)),
    ],
  };

  Message _msg(String conv, String sender, String text, Duration ago) =>
      Message(
        id: 'm${_seq++}',
        conversationId: conv,
        senderId: sender,
        content: text,
        createdAt: DateTime.now().subtract(ago),
        isMine: sender == kOfflineMeId,
      );

  Future<List<Conversation>> conversations() async =>
      List.unmodifiable(_convos);

  Conversation? byId(String id) {
    for (final c in _convos) {
      if (c.id == id) return c;
    }
    return null;
  }

  Stream<List<Message>> stream(String conversationId) {
    final controller = _controllers.putIfAbsent(
      conversationId,
      () => StreamController<List<Message>>.broadcast(),
    );
    // Seed the new listener with the current history.
    scheduleMicrotask(() => controller.add(_listFor(conversationId)));
    return controller.stream;
  }

  List<Message> _listFor(String id) =>
      List.unmodifiable(_messages[id] ?? const []);

  void _emit(String id) => _controllers[id]?.add(_listFor(id));

  void send(String conversationId, String text) {
    final list = _messages.putIfAbsent(conversationId, () => []);
    list.add(_msg(conversationId, kOfflineMeId, text, Duration.zero));
    _emit(conversationId);
    // Canned auto-reply so the realtime UI is demoable.
    Timer(const Duration(milliseconds: 1100), () {
      list.add(
        _msg(
          conversationId,
          'other',
          'Got it — thanks for the message! 👍',
          Duration.zero,
        ),
      );
      _emit(conversationId);
    });
  }

  void markRead(String conversationId) {
    final i = _convos.indexWhere((c) => c.id == conversationId);
    if (i != -1) _convos[i] = _convos[i].copyWith(unreadCount: 0);
  }
}

final _offline = _OfflineChat();
