// lib/src/presentation/widgets/chat/instructor_chat_panel.dart
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// ENVIRONMENT FIX: Import environment configuration
import '../../../core/config/environment.dart';

/// Chat Panel for Instructors
/// Features: Course chats (with admin powers), 1-on-1 student chats, Community chat
/// Includes: Emoji support, attachments, notifications
class InstructorChatPanel extends StatefulWidget {
  final String userId;
  final String userName;
  final List<Map<String, dynamic>> teachingCourses;
  final List<Map<String, dynamic>> students;
  final Function(int)? onUnreadCountChange;

  const InstructorChatPanel({
    super.key,
    required this.userId,
    required this.userName,
    required this.teachingCourses,
    required this.students,
    this.onUnreadCountChange,
  });

  @override
  State<InstructorChatPanel> createState() => _InstructorChatPanelState();
}

class _InstructorChatPanelState extends State<InstructorChatPanel>
    with SingleTickerProviderStateMixin {
  late IO.Socket socket;
  late TabController _tabController;

  final Map<String, List<ChatMessage>> _chatMessages = {};
  final Map<String, TextEditingController> _messageControllers = {};
  final Map<String, int> _unreadCounts = {};

  String? _selectedChatId;
  bool _isConnected = false;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeSocket();
    _setupChatRooms();
  }

  @override
  void dispose() {
    // CRITICAL FIX: Properly disconnect and clean up socket event listeners
    try {
      // Remove all event listeners to prevent memory leaks
      socket.off('message');
      socket.off('user_typing');
      socket.off('connect');
      socket.off('disconnect');
      socket.off('connect_error');

      // Disconnect the socket
      socket.disconnect();
      socket.dispose();
    } catch (e) {
      // Silently handle disposal errors
      print('Socket disposal error: $e');
    }

    _tabController.dispose();
    for (var controller in _messageControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeSocket() {
    // ENVIRONMENT FIX: Use Environment.socketUrl for automatic environment detection
    socket = IO.io(Environment.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false, // Prevent auto-connect spam
      'reconnection': Environment.socketReconnection, // Enable in production only
      'timeout': Environment.socketTimeout,
      'auth': {
        'userId': widget.userId,
        'userName': widget.userName,
        'role': 'instructor',
      },
    });

    socket.onConnect((_) {
      if (mounted) {
        setState(() {
          _isConnected = true;
        });
      }
      print('✅ Instructor Socket.IO Connected');
      _joinAllRooms();
    });

    socket.onDisconnect((_) {
      if (mounted) {
        setState(() {
          _isConnected = false;
        });
      }
      print('❌ Socket.IO Disconnected');
    });

    socket.onConnectError((error) {
      // Silently handle connection errors
      if (mounted) {
        setState(() {
          _isConnected = false;
        });
      }
    });

    socket.on('message', (data) {
      _handleIncomingMessage(data);
    });

    socket.on('user_typing', (data) {
      // Handle typing indicator
      print('User typing: $data');
    });

    // Only connect if Socket.IO is enabled (prevents 404 errors in development)
    if (Environment.socketEnabled) {
      try {
        socket.connect();
      } catch (e) {
        // Silently fail if Socket.IO server is not available
        print('⚠️ Socket.IO server not available');
      }
    } else {
      print('ℹ️ Socket.IO disabled (set SOCKET_ENABLED=true to enable)');
    }
  }

  void _setupChatRooms() {
    // Community chat
    _chatMessages['hosi_academy_community'] = [];
    _messageControllers['hosi_academy_community'] = TextEditingController();
    _unreadCounts['hosi_academy_community'] = 0;

    // Course group chats
    for (var course in widget.teachingCourses) {
      final chatId = 'chat_course_${course['id']}';
      _chatMessages[chatId] = [];
      _messageControllers[chatId] = TextEditingController();
      _unreadCounts[chatId] = 0;
    }

    // 1-on-1 chats with students - use direct_ prefix to match backend
    for (var student in widget.students) {
      // Format: direct_instructorId_studentId
      final chatId = 'direct_${widget.userId}_${student['id']}';
      _chatMessages[chatId] = [];
      _messageControllers[chatId] = TextEditingController();
      _unreadCounts[chatId] = 0;
    }
  }

  void _joinAllRooms() {
    // Join Hosi Academy Chat
    socket.emit('join_room', {'room': 'hosi_academy_community'});

    // Join each course group chat as admin
    for (var course in widget.teachingCourses) {
      socket.emit('join_room', {
        'room': 'chat_course_${course['id']}',
        'role': 'admin', // Instructor has admin privileges
      });
    }

    // Join 1-on-1 rooms for direct messages
    // Backend will auto-create rooms when messages are exchanged
    for (var student in widget.students) {
      final chatId = 'direct_${widget.userId}_${student['id']}';
      socket.emit('join_room', {
        'room': chatId,
        'role': 'instructor',
      });
    }

    print('✅ Joined all chat rooms');
  }

  void _handleIncomingMessage(dynamic data) {
    print('📥 Received message: $data');
    
    // Handle both direct message format and nested message format
    Map<String, dynamic> messageData;
    if (data is Map<String, dynamic>) {
      // Backend might send as {'message': {...}} or directly as {...}
      messageData = data['message'] ?? data;
    } else {
      return; // Ignore invalid data
    }

    final message = ChatMessage.fromJson(messageData);
    final chatId = message.chatId;

    setState(() {
      if (!_chatMessages.containsKey(chatId)) {
        _chatMessages[chatId] = [];
        _messageControllers[chatId] = TextEditingController();
        _unreadCounts[chatId] = 0;
      }

      _chatMessages[chatId]!.add(message);

      // Increment unread count if not viewing this chat
      if (_selectedChatId != chatId) {
        _unreadCounts[chatId] = (_unreadCounts[chatId] ?? 0) + 1;
        _updateTotalUnreadCount();
      }
    });
  }

  void _updateTotalUnreadCount() {
    final total = _unreadCounts.values.fold(0, (sum, count) => sum + count);
    if (widget.onUnreadCountChange != null) {
      widget.onUnreadCountChange!(total);
    }
  }

  void _sendMessage(String chatId) {
    final controller = _messageControllers[chatId];
    if (controller == null || controller.text.trim().isEmpty) return;

    // Extract receiver ID from chatId for direct messages
    String? receiverId;
    if (chatId.startsWith('direct_')) {
      // Format: direct_instructorId_studentId
      final parts = chatId.split('_');
      if (parts.length == 3) {
        final instructorId = parts[1];
        final studentId = parts[2];
        // If current user is instructor, receiver is student
        receiverId = widget.userId == instructorId ? studentId : instructorId;
      }
    }

    // Create message in Socket.io backend format
    final message = {
      'chatId': chatId,
      'content': controller.text,
      'senderId': widget.userId,
      'senderName': widget.userName,
      'receiverId': receiverId,
      'type': 'text',
      'timestamp': DateTime.now().toIso8601String(),
    };

    print('📤 Sending message: $message');
    socket.emit('send_message', message);

    // Optimistically add message to UI
    setState(() {
      _chatMessages[chatId]!.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        chatId: chatId,
        senderId: widget.userId,
        senderName: widget.userName,
        content: controller.text,
        timestamp: DateTime.now(),
        type: 'text',
        isInstructor: true,
        receiverId: receiverId,
      ));
    });

    controller.clear();
    setState(() {
      _showEmojiPicker = false;
    });
  }

  void _deleteMessage(String roomId, String messageId) {
    // Instructor admin power: delete messages
    socket.emit('delete_message', {
      'room': roomId,
      'messageId': messageId,
      'adminId': widget.userId,
    });

    setState(() {
      _chatMessages[roomId]?.removeWhere((msg) => msg.id == messageId);
    });
  }

  void _pinMessage(String roomId, String messageId) {
    // Instructor admin power: pin important messages
    socket.emit('pin_message', {
      'room': roomId,
      'messageId': messageId,
      'adminId': widget.userId,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(theme, colors),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: colors.primary,
            unselectedLabelColor: colors.onSurface,
            indicatorColor: colors.primary,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Community'),
                    if ((_unreadCounts['hosi_academy_community'] ?? 0) > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${_unreadCounts['hosi_academy_community']}',
                          style: TextStyle(color: colors.onError, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Courses'),
                    if (_getCourseUnreadCount() > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$_getCourseUnreadCount()',
                          style: TextStyle(color: colors.onError, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('1-on-1'),
                    if (_getPrivateUnreadCount() > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$_getPrivateUnreadCount()',
                          style: TextStyle(color: colors.onError, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCommunityChat(theme, colors),
                _buildCoursesChat(theme, colors),
                _buildPrivateChats(theme, colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.chat, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Instructor Chat',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Connection indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _isConnected ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  int _getCourseUnreadCount() {
    int total = 0;
    for (var course in widget.teachingCourses) {
      final roomId = 'course_${course['id']}';
      total += _unreadCounts[roomId] ?? 0;
    }
    return total;
  }

  int _getPrivateUnreadCount() {
    int total = 0;
    for (var key in _unreadCounts.keys) {
      if (key.startsWith('private_')) {
        total += _unreadCounts[key] ?? 0;
      }
    }
    return total;
  }

  // Community Chat
  Widget _buildCommunityChat(ThemeData theme, ColorScheme colors) {
    return _buildChatView('hosi_academy_community', 'Hosi Academy Chat', theme, colors);
  }

  // Courses Chat (List of courses)
  Widget _buildCoursesChat(ThemeData theme, ColorScheme colors) {
    if (_selectedChatId != null && _selectedChatId!.startsWith('course_')) {
      final course = widget.teachingCourses.firstWhere(
        (c) => 'course_${c['id']}' == _selectedChatId,
        orElse: () => {'title': 'Course Chat'},
      );
      return _buildChatView(_selectedChatId!, course['title'], theme, colors, isInstructorAdmin: true);
    }

    return ListView.builder(
      itemCount: widget.teachingCourses.length,
      itemBuilder: (context, index) {
        final course = widget.teachingCourses[index];
        final roomId = 'course_${course['id']}';
        final unreadCount = _unreadCounts[roomId] ?? 0;

        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.school, color: colors.primary),
          ),
          title: Text(course['title']),
          subtitle: Text('${course['students']} students'),
          trailing: unreadCount > 0
              ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unreadCount',
                    style: TextStyle(color: colors.onError, fontSize: 12),
                  ),
                )
              : const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            setState(() {
              _selectedChatId = roomId;
              _unreadCounts[roomId] = 0;
              _updateTotalUnreadCount();
            });
          },
        );
      },
    );
  }

  // Private Chats (List of students)
  Widget _buildPrivateChats(ThemeData theme, ColorScheme colors) {
    final students = widget.students;

    if (_selectedChatId != null && _selectedChatId!.startsWith('private_')) {
      final studentName = students.firstWhere(
        (s) => _selectedChatId!.contains(s['id']!),
        orElse: () => {'name': 'Student'},
      )['name'];
      return _buildChatView(_selectedChatId!, studentName!, theme, colors);
    }

    return ListView.builder(
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final roomId = 'private_${widget.userId}_${student['id']}';
        final unreadCount = _unreadCounts[roomId] ?? 0;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: colors.primary.withValues(alpha: 0.1),
            child: Text(student['name']![0], style: TextStyle(color: colors.primary)),
          ),
          title: Text(student['name']!),
          subtitle: const Text('Tap to chat'),
          trailing: unreadCount > 0
              ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unreadCount',
                    style: TextStyle(color: colors.onError, fontSize: 12),
                  ),
                )
              : null,
          onTap: () {
            setState(() {
              _selectedChatId = roomId;
              _unreadCounts[roomId] = 0;
              _updateTotalUnreadCount();
            });
          },
        );
      },
    );
  }

  // Chat View (messages + input)
  Widget _buildChatView(String roomId, String title, ThemeData theme, ColorScheme colors,
      {bool isInstructorAdmin = false}) {
    final messages = _chatMessages[roomId] ?? [];
    final controller = _messageControllers[roomId]!;

    return Column(
      children: [
        // Chat header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: colors.outline.withValues(alpha: 0.2)),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedChatId = null;
                  });
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isInstructorAdmin)
                      Text(
                        'Admin',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                  ],
                ),
              ),
              if (isInstructorAdmin)
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    // Show admin options
                    _showAdminOptions(context, roomId, theme, colors);
                  },
                ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Text(
                    'No messages yet',
                    style: TextStyle(color: colors.onSurface),
                  ),
                )
              : ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    return _buildMessageBubble(message, theme, colors, roomId, isInstructorAdmin);
                  },
                ),
        ),

        // Input area
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              top: BorderSide(color: colors.outline.withValues(alpha: 0.2)),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.emoji_emotions),
                onPressed: () {
                  setState(() {
                    _showEmojiPicker = !_showEmojiPicker;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: () {
                  // TODO: Implement file attachment
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('File attachment coming soon')),
                  );
                },
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(roomId),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: colors.primary),
                onPressed: () => _sendMessage(roomId),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(
      ChatMessage message, ThemeData theme, ColorScheme colors, String roomId, bool isAdmin) {
    final isOwnMessage = message.senderId == widget.userId;

    return GestureDetector(
      onLongPress: () {
        if (isAdmin) {
          _showMessageOptions(context, message, roomId, theme, colors);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 250),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOwnMessage
                    ? colors.primary.withValues(alpha: 0.2)
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isOwnMessage)
                    Text(
                      message.senderName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  Text(message.content),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(
      BuildContext context, ChatMessage message, String roomId, ThemeData theme, ColorScheme colors) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.push_pin),
              title: const Text('Pin Message'),
              onTap: () {
                Navigator.pop(context);
                _pinMessage(roomId, message.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Message'),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(roomId, message.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAdminOptions(BuildContext context, String roomId, ThemeData theme, ColorScheme colors) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.rule),
              title: const Text('Set Chat Rules'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement set chat rules
              },
            ),
            ListTile(
              leading: const Icon(Icons.announcement),
              title: const Text('Send Announcement'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement send announcement
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('View Chat History'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement view history
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final String type;
  final bool isInstructor;
  final String? receiverId;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.type = 'text',
    this.isInstructor = false,
    this.receiverId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Handle both backend socket.io format and legacy format
    return ChatMessage(
      id: json['id'] ?? json['messageId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: json['chatId'] ?? json['room'] ?? '',
      senderId: json['senderId'] ?? json['userId'] ?? '',
      senderName: json['senderName'] ?? json['userName'] ?? 'User',
      content: json['content'] ?? json['message'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      type: json['type'] ?? 'text',
      isInstructor: json['isInstructor'] ?? json['senderRole'] == 'instructor',
      receiverId: json['receiverId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'receiverId': receiverId,
    };
  }
}
