// lib/src/data/models/chat_message.dart

enum MessageType {
  text,
  image,
  file,
  system;
}

enum ChatType {
  community, // Course community chat
  direct, // Student to Instructor
  group; // Group discussions
}

class ChatMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? replyToId;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.isRead = false,
    this.replyToId,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      chatRoomId: json['chat_room_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String,
      senderAvatar: json['sender_avatar'] as String?,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['is_read'] as bool? ?? false,
      replyToId: json['reply_to_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_room_id': chatRoomId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'reply_to_id': replyToId,
      'metadata': metadata,
    };
  }

  ChatMessage copyWith({
    bool? isRead,
  }) {
    return ChatMessage(
      id: id,
      chatRoomId: chatRoomId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: content,
      type: type,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      replyToId: replyToId,
      metadata: metadata,
    );
  }
}

class ChatRoom {
  final String id;
  final String name;
  final ChatType type;
  final String courseId;
  final String? courseName;
  final List<String> participants;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final bool isActive;

  ChatRoom({
    required this.id,
    required this.name,
    required this.type,
    required this.courseId,
    this.courseName,
    this.participants = const [],
    this.lastMessage,
    this.unreadCount = 0,
    this.isActive = true,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ChatType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChatType.community,
      ),
      courseId: json['course_id'] as String,
      courseName: json['course_name'] as String?,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      lastMessage: json['last_message'] != null
          ? ChatMessage.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'course_id': courseId,
      'course_name': courseName,
      'participants': participants,
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'is_active': isActive,
    };
  }
}
