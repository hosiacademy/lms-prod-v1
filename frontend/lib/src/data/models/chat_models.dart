import 'package:intl/intl.dart';

class ChatRoom {
  final String id;
  final String name;
  final String? description;
  final String type; // 'one_on_one', 'group', 'community', 'announcement'
  final DateTime updatedAt;
  final ChatMessage? lastMessage;
  final int participantCount;
  final int unreadCount;

  ChatRoom({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.updatedAt,
    this.lastMessage,
    this.participantCount = 0,
    this.unreadCount = 0,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'group',
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastMessage: json['lastMessage'] != null
          ? ChatMessage.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      participantCount: json['participantCount'] as int? ?? 0,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  String get lastMessageTime {
    if (lastMessage == null) return '';
    final now = DateTime.now();
    final difference = now.difference(lastMessage!.createdAt);
    if (difference.inDays > 0) {
      return DateFormat('MMM d').format(lastMessage!.createdAt);
    }
    return DateFormat('HH:mm').format(lastMessage!.createdAt);
  }
}

class ChatMessage {
  final int id;
  final String senderId;
  final String senderName;
  final String content;
  final String type; // 'text', 'announcement', 'image', 'file', 'audio', 'video'
  final DateTime createdAt;
  final bool isRead;
  final List<String> attachments;
  final bool senderIsExecutive;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.attachments = const [],
    this.senderIsExecutive = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Backend uses both 'id' and 'socket_message_id' (which is 'id' in socketio format)
    // Here we map from the common MessageSerializer
    return ChatMessage(
      id: json['id'] is int ? json['id'] : 0,
      senderId: (json['sender']?['id'] ?? json['senderId'] ?? '').toString(),
      senderName: json['sender']?['name'] ?? json['sender']?['full_name'] ?? json['senderName'] ?? 'Unknown',
      content: json['message'] ?? json['content'] ?? '',
      type: json['message_type'] ?? json['type'] ?? 'text',
      createdAt: DateTime.parse(json['created_at'] ?? json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['seen'] ?? json['isRead'] ?? false,
      attachments: List<String>.from(json['attachments'] ?? []),
      senderIsExecutive: json['sender']?['is_executive'] ?? json['senderIsExecutive'] ?? false,
    );
  }
}

class ChatParticipant {
  final int id;
  final String name;
  final String? profilePicture;
  final int roleId;
  final bool isExecutive;

  ChatParticipant({
    required this.id,
    required this.name,
    this.profilePicture,
    required this.roleId,
    this.isExecutive = false,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id'] as int,
      name: json['full_name'] ?? json['name'] ?? 'Unknown',
      profilePicture: json['profile_picture'] ?? json['image'],
      roleId: json['role_id'] as int? ?? 3,
      isExecutive: json['is_executive'] as bool? ?? false,
    );
  }
}
