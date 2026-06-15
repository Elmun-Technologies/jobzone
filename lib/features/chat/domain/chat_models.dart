/// A direct conversation summary for the chat list.
class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    this.avatarUrl,
    this.subtitle,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  final String id;
  final String title;
  final String? avatarUrl;
  final String? subtitle;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  Conversation copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) => Conversation(
    id: id,
    title: title,
    avatarUrl: avatarUrl,
    subtitle: subtitle,
    lastMessage: lastMessage ?? this.lastMessage,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    unreadCount: unreadCount ?? this.unreadCount,
  );
}

/// A single chat message.
class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.content,
    this.type = 'text',
    this.attachmentUrl,
    required this.createdAt,
    required this.isMine,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String? content;
  final String type;
  final String? attachmentUrl;
  final DateTime createdAt;
  final bool isMine;

  factory Message.fromMap(Map<String, dynamic> m, String? currentUid) {
    final sender = (m['sender_id'] ?? '') as String;
    return Message(
      id: (m['id'] ?? '') as String,
      conversationId: (m['conversation_id'] ?? '') as String,
      senderId: sender,
      content: m['content'] as String?,
      type: (m['type'] ?? 'text') as String,
      attachmentUrl: m['attachment_url'] as String?,
      createdAt:
          DateTime.tryParse('${m['created_at']}')?.toLocal() ?? DateTime.now(),
      isMine: currentUid != null && sender == currentUid,
    );
  }
}
