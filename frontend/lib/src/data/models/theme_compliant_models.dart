// lib/src/data/models/theme_compliant_models.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// User roles from your existing dashboard
enum UserRole { student, instructor, facilitator, admin, partner }

extension UserRoleExtension on UserRole {
  String get label {
    return switch (this) {
      UserRole.student => 'Student Portal',
      UserRole.instructor => 'Instructor Portal',
      UserRole.facilitator => 'Facilitator Portal',
      UserRole.admin => 'Admin Portal',
      UserRole.partner => 'Partner Portal',
    };
  }

  IconData get icon {
    return switch (this) {
      UserRole.student => Icons.school,
      UserRole.instructor => Icons.create,
      UserRole.facilitator => Icons.group_work,
      UserRole.admin => Icons.admin_panel_settings,
      UserRole.partner =>
        Icons.handshake, // ← FIXED: partner_exchange doesn't exist
    };
  }
}

/// Content providers for course delivery
enum ContentProvider {
  bigBlueButton,
  aiCerts,
  moodle,
  canvas,
  customPartner,
  hosiNative
}

extension ContentProviderExtension on ContentProvider {
  String get name {
    return switch (this) {
      ContentProvider.bigBlueButton => 'BigBlueButton',
      ContentProvider.aiCerts => 'AICERTS',
      ContentProvider.moodle => 'Moodle',
      ContentProvider.canvas => 'Canvas',
      ContentProvider.customPartner => 'Partner',
      ContentProvider.hosiNative => 'Hosi Native',
    };
  }

  IconData get icon {
    return switch (this) {
      ContentProvider.bigBlueButton => Icons.videocam,
      ContentProvider.aiCerts => Icons.verified,
      ContentProvider.moodle => Icons.school,
      ContentProvider.canvas => Icons.dashboard,
      ContentProvider.customPartner =>
        Icons.handshake, // ← FIXED: partner_exchange doesn't exist
      ContentProvider.hosiNative => Icons.home,
    };
  }

  Color get color {
    return switch (this) {
      ContentProvider.bigBlueButton => const Color(0xFF0066CC),
      ContentProvider.aiCerts => const Color(0xFF00D084),
      ContentProvider.moodle => const Color(0xFFF98012),
      ContentProvider.canvas => const Color(0xFFE41E3C),
      ContentProvider.customPartner => const Color(0xFF9B51E0),
      ContentProvider.hosiNative => const Color(0xFF0693E3),
    };
  }
}

/// User presence status for chat
enum UserStatus { online, offline, away, busy, invisible }

extension UserStatusExtension on UserStatus {
  Color get color {
    return switch (this) {
      UserStatus.online => Colors.green,
      UserStatus.offline => Colors.grey,
      UserStatus.away => Colors.orange,
      UserStatus.busy => Colors.red,
      UserStatus.invisible => Colors.grey.shade600,
    };
  }

  String get label {
    return switch (this) {
      UserStatus.online => 'Online',
      UserStatus.offline => 'Offline',
      UserStatus.away => 'Away',
      UserStatus.busy => 'Busy',
      UserStatus.invisible => 'Invisible',
    };
  }
}

/// Chat types for different conversation contexts
enum ChatType { oneOnOne, group, course, community, announcement, support }

extension ChatTypeExtension on ChatType {
  String get label {
    return switch (this) {
      ChatType.oneOnOne => 'Direct Message',
      ChatType.group => 'Group Chat',
      ChatType.course => 'Course Discussion',
      ChatType.community => 'Community',
      ChatType.announcement => 'Announcements',
      ChatType.support => 'Support',
    };
  }

  IconData get icon {
    return switch (this) {
      ChatType.oneOnOne => Icons.person,
      ChatType.group => Icons.group,
      ChatType.course => Icons.school,
      ChatType.community => Icons.forum,
      ChatType.announcement => Icons.announcement,
      ChatType.support => Icons.support,
    };
  }
}

/// Message types for different content
enum MessageType { text, image, file, audio, video, announcement, poll, system }

/// Course content model
class CourseContent extends Equatable {
  final String id;
  final String title;
  final String? description;
  final ContentProvider provider;
  final Map<String, dynamic> providerData;
  final DateTime? scheduledTime;
  final Duration? duration;
  final double progress;
  final bool isLive;
  final String? certificationId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CourseContent({
    required this.id,
    required this.title,
    this.description,
    required this.provider,
    this.providerData = const {},
    this.scheduledTime,
    this.duration,
    this.progress = 0.0,
    this.isLive = false,
    this.certificationId,
    required this.createdAt,
    this.updatedAt,
  });

  factory CourseContent.fromJson(Map<String, dynamic> json) {
    return CourseContent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      provider: ContentProvider.values.firstWhere(
        (e) => e.name == json['provider'],
        orElse: () => ContentProvider.hosiNative,
      ),
      providerData: Map<String, dynamic>.from(json['providerData'] ?? {}),
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.parse(json['scheduledTime'])
          : null,
      duration:
          json['duration'] != null ? Duration(minutes: json['duration']) : null,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      isLive: json['isLive'] ?? false,
      certificationId: json['certificationId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'provider': provider.name,
      'providerData': providerData,
      'scheduledTime': scheduledTime?.toIso8601String(),
      'duration': duration?.inMinutes,
      'progress': progress,
      'isLive': isLive,
      'certificationId': certificationId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  CourseContent copyWith({
    String? id,
    String? title,
    String? description,
    ContentProvider? provider,
    Map<String, dynamic>? providerData,
    DateTime? scheduledTime,
    Duration? duration,
    double? progress,
    bool? isLive,
    String? certificationId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourseContent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      provider: provider ?? this.provider,
      providerData: providerData ?? this.providerData,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      duration: duration ?? this.duration,
      progress: progress ?? this.progress,
      isLive: isLive ?? this.isLive,
      certificationId: certificationId ?? this.certificationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isUpcoming =>
      scheduledTime != null && scheduledTime!.isAfter(DateTime.now());
  bool get isInProgress => progress > 0 && progress < 1;
  bool get isCompleted => progress >= 1;

  String get progressText => '% complete';

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        provider,
        providerData,
        scheduledTime,
        duration,
        progress,
        isLive,
        certificationId,
        createdAt,
        updatedAt,
      ];
}

/// Live session model for BigBlueButton
class LiveSession extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final ContentProvider provider;
  final String meetingId;
  final String? moderatorPassword;
  final String? attendeePassword;
  final bool isRecording;
  final bool hasStarted;
  final bool hasEnded;
  final int participantCount;
  final int? maxParticipants;
  final Map<String, dynamic> metadata;

  const LiveSession({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.provider,
    required this.meetingId,
    this.moderatorPassword,
    this.attendeePassword,
    this.isRecording = false,
    this.hasStarted = false,
    this.hasEnded = false,
    this.participantCount = 0,
    this.maxParticipants,
    this.metadata = const {},
  });

  factory LiveSession.fromJson(Map<String, dynamic> json) {
    return LiveSession(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      provider: ContentProvider.values.firstWhere(
        (e) => e.name == json['provider'],
        orElse: () => ContentProvider.bigBlueButton,
      ),
      meetingId: json['meetingId'],
      moderatorPassword: json['moderatorPassword'],
      attendeePassword: json['attendeePassword'],
      isRecording: json['isRecording'] ?? false,
      hasStarted: json['hasStarted'] ?? false,
      hasEnded: json['hasEnded'] ?? false,
      participantCount: json['participantCount'] ?? 0,
      maxParticipants: json['maxParticipants'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'provider': provider.name,
      'meetingId': meetingId,
      'moderatorPassword': moderatorPassword,
      'attendeePassword': attendeePassword,
      'isRecording': isRecording,
      'hasStarted': hasStarted,
      'hasEnded': hasEnded,
      'participantCount': participantCount,
      'maxParticipants': maxParticipants,
      'metadata': metadata,
    };
  }

  bool get isActive =>
      DateTime.now().isAfter(startTime) &&
      DateTime.now().isBefore(endTime) &&
      !hasEnded;
  bool get isUpcoming => DateTime.now().isBefore(startTime);
  bool get hasPassed => DateTime.now().isAfter(endTime);

  Duration get duration => endTime.difference(startTime);
  Duration get timeUntilStart => startTime.difference(DateTime.now());
  Duration get timeUntilEnd => endTime.difference(DateTime.now());

  String get statusText {
    if (hasEnded) return 'Ended';
    if (isActive) return 'Live Now';
    if (isUpcoming) {
      if (timeUntilStart.inDays > 0) {
        return 'In ${timeUntilStart.inDays} days';
      } else if (timeUntilStart.inHours > 0) {
        return 'In ${timeUntilStart.inHours} hours';
      } else {
        return 'In ${timeUntilStart.inMinutes} minutes';
      }
    }
    return 'Scheduled';
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        startTime,
        endTime,
        provider,
        meetingId,
        moderatorPassword,
        attendeePassword,
        isRecording,
        hasStarted,
        hasEnded,
        participantCount,
        maxParticipants,
        metadata,
      ];
}

/// Chat participant model
class ChatParticipant extends Equatable {
  final String id;
  final String name;
  final String? avatarUrl;
  final UserRole role;
  final UserStatus status;
  final DateTime? lastSeen;
  final bool isTyping;
  final String? currentCourseId;
  final Map<String, dynamic> metadata;

  const ChatParticipant({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.role,
    this.status = UserStatus.offline,
    this.lastSeen,
    this.isTyping = false,
    this.currentCourseId,
    this.metadata = const {},
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id'],
      name: json['name'],
      avatarUrl: json['avatarUrl'],
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.student,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => UserStatus.offline,
      ),
      lastSeen:
          json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
      isTyping: json['isTyping'] ?? false,
      currentCourseId: json['currentCourseId'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'role': role.name,
      'status': status.name,
      'lastSeen': lastSeen?.toIso8601String(),
      'isTyping': isTyping,
      'currentCourseId': currentCourseId,
      'metadata': metadata,
    };
  }

  ChatParticipant copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    UserRole? role,
    UserStatus? status,
    DateTime? lastSeen,
    bool? isTyping,
    String? currentCourseId,
    Map<String, dynamic>? metadata,
  }) {
    return ChatParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      isTyping: isTyping ?? this.isTyping,
      currentCourseId: currentCourseId ?? this.currentCourseId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        avatarUrl,
        role,
        status,
        lastSeen,
        isTyping,
        currentCourseId,
        metadata,
      ];
}

/// Chat message model
class ChatMessage extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final DateTime? editedAt;
  final bool isRead;
  final bool isEdited;
  final bool isDeleted;
  final List<String>? attachments;
  final String? replyToId;
  final Map<String, dynamic> metadata;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.editedAt,
    this.isRead = false,
    this.isEdited = false,
    this.isDeleted = false,
    this.attachments,
    this.replyToId,
    this.metadata = const {},
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      chatId: json['chatId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      content: json['content'],
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      editedAt:
          json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
      isRead: json['isRead'] ?? false,
      isEdited: json['isEdited'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : null,
      replyToId: json['replyToId'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'isRead': isRead,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'attachments': attachments,
      'replyToId': replyToId,
      'metadata': metadata,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      return '${difference.inDays ~/ 365}y ago';
    } else if (difference.inDays > 30) {
      return '${difference.inDays ~/ 30}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  List<Object?> get props => [
        id,
        chatId,
        senderId,
        senderName,
        content,
        type,
        timestamp,
        editedAt,
        isRead,
        isEdited,
        isDeleted,
        attachments,
        replyToId,
        metadata,
      ];
}

/// Chat room model
class ChatRoom extends Equatable {
  final String id;
  final String name;
  final String? description;
  final ChatType type;
  final List<ChatParticipant> participants;
  final String? courseId;
  final String? instructorId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final bool isPinned;
  final bool isArchived;
  final bool isMuted;
  final Map<String, dynamic> settings;

  const ChatRoom({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.participants,
    this.courseId,
    this.instructorId,
    required this.createdAt,
    this.updatedAt,
    this.lastMessage,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isArchived = false,
    this.isMuted = false,
    this.settings = const {},
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: ChatType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChatType.group,
      ),
      participants: json['participants'] != null
          ? List<ChatParticipant>.from(
              json['participants'].map((x) => ChatParticipant.fromJson(x)))
          : [],
      courseId: json['courseId'],
      instructorId: json['instructorId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      lastMessage: json['lastMessage'] != null
          ? ChatMessage.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      isPinned: json['isPinned'] ?? false,
      isArchived: json['isArchived'] ?? false,
      isMuted: json['isMuted'] ?? false,
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'participants': participants.map((x) => x.toJson()).toList(),
      'courseId': courseId,
      'instructorId': instructorId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'isMuted': isMuted,
      'settings': settings,
    };
  }

  ChatRoom copyWith({
    String? id,
    String? name,
    String? description,
    ChatType? type,
    List<ChatParticipant>? participants,
    String? courseId,
    String? instructorId,
    DateTime? createdAt,
    DateTime? updatedAt,
    ChatMessage? lastMessage,
    int? unreadCount,
    bool? isPinned,
    bool? isArchived,
    bool? isMuted,
    Map<String, dynamic>? settings,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      courseId: courseId ?? this.courseId,
      instructorId: instructorId ?? this.instructorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
      settings: settings ?? this.settings,
    );
  }

  String get participantNames {
    if (participants.length <= 2) {
      return participants.map((p) => p.name).join(', ');
    }
    return '${participants.length} participants';
  }

  bool get hasUnread => unreadCount > 0;
  bool get isDirectMessage => type == ChatType.oneOnOne;
  bool get isGroupChat => type == ChatType.group;
  bool get isCourseChat => type == ChatType.course;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        type,
        participants,
        courseId,
        instructorId,
        createdAt,
        updatedAt,
        lastMessage,
        unreadCount,
        isPinned,
        isArchived,
        isMuted,
        settings,
      ];
}
