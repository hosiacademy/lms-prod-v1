// lib/src/presentation/widgets/chat/chat_panel.dart
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// ENVIRONMENT FIX: Import environment configuration
import '../../../core/config/environment.dart';

/// Chat Panel with Socket.IO - Right side of dashboard
/// Includes: Course group chats, 1-on-1 chats, Hosi Academy Community
///
/// PAYWALL ENFORCEMENT:
/// - Community chat: ALWAYS accessible (even when suspended)
/// - Course chats: Only accessible with active subscription
class ChatPanel extends StatefulWidget {
  final String userId;
  final String userName;
  final List<Map<String, dynamic>> enrolledCourses;
  final bool canAccessCourseChats; // PAYWALL: Controls course chat access

  const ChatPanel({
    super.key,
    required this.userId,
    required this.userName,
    required this.enrolledCourses,
    this.canAccessCourseChats =
        true, // Default to true for backwards compatibility
  });

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel>
    with SingleTickerProviderStateMixin {
  late IO.Socket socket;
  late TabController _tabController;

  final Map<String, List<ChatMessage>> _chatMessages = {};
  final Map<String, TextEditingController> _messageControllers = {};
  final Map<String, int> _unreadCounts = {};

  String? _selectedChatId;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeSocket();
    _setupChatRooms();
  }

  void _initializeSocket() {
    // ENVIRONMENT FIX: Use Environment.socketUrl for automatic environment detection
    socket = IO.io(Environment.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false, // Prevent auto-connect spam
      'reconnection':
          Environment.socketReconnection, // Enable in production only
      'timeout': Environment.socketTimeout,
      'auth': {
        'userId': widget.userId,
        'userName': widget.userName,
      },
    });

    socket.onConnect((_) {
      if (mounted) {
        setState(() {
          _isConnected = true;
        });
      }
      print('✅ Socket.IO Connected');

      // Join all relevant rooms
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

    // Listen for incoming messages
    socket.on('message', (data) {
      _handleIncomingMessage(data);
    });

    // Listen for typing indicators
    socket.on('user_typing', (data) {
      // TODO: Show typing indicator
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

  void _joinAllRooms() {
    // Join Hosi Academy Community room
    socket.emit('join_room', {'room': 'hosi_academy_community'});

    // Join each course group chat
    for (var course in widget.enrolledCourses) {
      socket.emit('join_room', {'room': 'course_${course['id']}'});
    }

    // TODO: Join 1-on-1 rooms with instructors
  }

  void _setupChatRooms() {
    // Initialize Hosi Academy Community chat
    _chatMessages['hosi_academy_community'] = [];
    _messageControllers['hosi_academy_community'] = TextEditingController();
    _unreadCounts['hosi_academy_community'] = 0;

    // Initialize course group chats
    for (var course in widget.enrolledCourses) {
      final chatId = 'course_${course['id']}';
      _chatMessages[chatId] = [];
      _messageControllers[chatId] = TextEditingController();
      _unreadCounts[chatId] = 0;
    }

    // Initialize 1-on-1 instructor chats
    for (var course in widget.enrolledCourses) {
      final chatId = 'instructor_${course['id']}';
      _chatMessages[chatId] = [];
      _messageControllers[chatId] = TextEditingController();
      _unreadCounts[chatId] = 0;
    }
  }

  void _handleIncomingMessage(dynamic data) {
    final message = ChatMessage.fromJson(data);
    final chatId = data['room'] ?? 'hosi_academy_community';

    setState(() {
      _chatMessages[chatId]?.add(message);

      // Increment unread count if not viewing this chat
      if (_selectedChatId != chatId) {
        _unreadCounts[chatId] = (_unreadCounts[chatId] ?? 0) + 1;
      }
    });
  }

  void _sendMessage(String chatId, String room) {
    final controller = _messageControllers[chatId];
    if (controller == null || controller.text.trim().isEmpty) return;

    final message = {
      'room': room,
      'userId': widget.userId,
      'userName': widget.userName,
      'message': controller.text.trim(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    socket.emit('send_message', message);

    // Add to local messages
    setState(() {
      _chatMessages[chatId]?.add(ChatMessage.fromJson(message));
    });

    controller.clear();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        // Chat header with connection status
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              bottom: BorderSide(
                color: colors.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Chats',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _isConnected ? 'Connected' : 'Offline',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _isConnected ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),

        // Tabs: Community | Course Groups | 1-on-1
        TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurface,
          indicatorColor: colors.primary,
          tabs: [
            Tab(
              icon: Badge(
                label: _unreadCounts['hosi_academy_community']! > 0
                    ? Text('${_unreadCounts['hosi_academy_community']}')
                    : null,
                child: const Icon(Icons.group),
              ),
              text: 'Community',
            ),
            Tab(
              icon: Badge(
                label: _getCourseUnreadTotal() > 0
                    ? Text('${_getCourseUnreadTotal()}')
                    : null,
                child: const Icon(Icons.school),
              ),
              text: 'Courses',
            ),
            Tab(
              icon: Badge(
                label: _getInstructorUnreadTotal() > 0
                    ? Text('${_getInstructorUnreadTotal()}')
                    : null,
                child: const Icon(Icons.person),
              ),
              text: '1-on-1',
            ),
          ],
        ),

        // Chat content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCommunityChat(theme, colors),
              _buildCourseChats(theme, colors),
              _buildOneOnOneChats(theme, colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityChat(ThemeData theme, ColorScheme colors) {
    return _buildChatInterface(
      chatId: 'hosi_academy_community',
      room: 'hosi_academy_community',
      title: 'Hosi Academy Chat',
      subtitle: 'All current and former students',
      theme: theme,
      colors: colors,
    );
  }

  Widget _buildCourseChats(ThemeData theme, ColorScheme colors) {
    // PAYWALL: Block course chats if subscription is suspended
    if (!widget.canAccessCourseChats) {
      return _buildPaywallScreen(
        icon: Icons.school,
        title: 'Course Chats Locked',
        message:
            'Your subscription is suspended. Pay to restore access to course chats.',
        theme: theme,
        colors: colors,
      );
    }

    if (_selectedChatId == null || !_selectedChatId!.startsWith('course_')) {
      return ListView.builder(
        itemCount: widget.enrolledCourses.length,
        itemBuilder: (context, index) {
          final course = widget.enrolledCourses[index];
          final chatId = 'course_${course['id']}';
          final unread = _unreadCounts[chatId] ?? 0;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: colors.primary.withValues(alpha: 0.1),
              child: Icon(Icons.school, color: colors.primary),
            ),
            title: Text(course['title']),
            subtitle: Text('Group chat with all students'),
            trailing: unread > 0
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unread',
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            onTap: () {
              setState(() {
                _selectedChatId = chatId;
                _unreadCounts[chatId] = 0;
              });
            },
          );
        },
      );
    }

    // Show selected course chat
    final selectedCourse = widget.enrolledCourses.firstWhere(
      (c) => 'course_${c['id']}' == _selectedChatId,
    );

    return Column(
      children: [
        ListTile(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _selectedChatId = null;
              });
            },
          ),
          title: Text(selectedCourse['title']),
          subtitle: const Text('Course Group Chat'),
        ),
        Expanded(
          child: _buildChatInterface(
            chatId: _selectedChatId!,
            room: _selectedChatId!,
            title: selectedCourse['title'],
            subtitle: 'Course Group Chat',
            theme: theme,
            colors: colors,
          ),
        ),
      ],
    );
  }

  Widget _buildOneOnOneChats(ThemeData theme, ColorScheme colors) {
    // PAYWALL: Block 1-on-1 instructor chats if subscription is suspended
    if (!widget.canAccessCourseChats) {
      return _buildPaywallScreen(
        icon: Icons.person,
        title: 'Instructor Chats Locked',
        message:
            'Your subscription is suspended. Pay to restore access to instructor chats.',
        theme: theme,
        colors: colors,
      );
    }

    if (_selectedChatId == null ||
        !_selectedChatId!.startsWith('instructor_')) {
      return ListView.builder(
        itemCount: widget.enrolledCourses.length,
        itemBuilder: (context, index) {
          final course = widget.enrolledCourses[index];
          final chatId = 'instructor_${course['id']}';
          final unread = _unreadCounts[chatId] ?? 0;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: colors.secondary.withValues(alpha: 0.1),
              child: Icon(Icons.person, color: colors.secondary),
            ),
            title: Text(course['instructor']),
            subtitle: Text(course['title']),
            trailing: unread > 0
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unread',
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            onTap: () {
              setState(() {
                _selectedChatId = chatId;
                _unreadCounts[chatId] = 0;
              });
            },
          );
        },
      );
    }

    // Show selected instructor chat
    final selectedCourse = widget.enrolledCourses.firstWhere(
      (c) => 'instructor_${c['id']}' == _selectedChatId,
    );

    return Column(
      children: [
        ListTile(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _selectedChatId = null;
              });
            },
          ),
          title: Text(selectedCourse['instructor']),
          subtitle: Text('1-on-1 Chat • ${selectedCourse['title']}'),
        ),
        Expanded(
          child: _buildChatInterface(
            chatId: _selectedChatId!,
            room: _selectedChatId!,
            title: selectedCourse['instructor'],
            subtitle: '1-on-1 Chat',
            theme: theme,
            colors: colors,
          ),
        ),
      ],
    );
  }

  Widget _buildChatInterface({
    required String chatId,
    required String room,
    required String title,
    required String subtitle,
    required ThemeData theme,
    required ColorScheme colors,
  }) {
    final messages = _chatMessages[chatId] ?? [];
    final controller = _messageControllers[chatId];

    return Column(
      children: [
        // Messages list
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start the conversation!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    final isMe = message.userId == widget.userId;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: isMe ? colors.primary : colors.surface,
                          gradient: isMe
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    colors.primary,
                                    colors.primary.withValues(alpha: 0.85),
                                  ],
                                )
                              : null,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft:
                                isMe ? const Radius.circular(16) : Radius.zero,
                            bottomRight:
                                isMe ? Radius.zero : const Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadow.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: !isMe
                              ? Border.all(
                                  color: colors.outlineVariant
                                      .withValues(alpha: 0.5))
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  message.userName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.primary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            Text(
                              message.message,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    isMe ? colors.onPrimary : colors.onSurface,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(message.timestamp),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isMe
                                        ? colors.onPrimary
                                            .withValues(alpha: 0.7)
                                        : colors.onSurfaceVariant,
                                    fontSize: 9,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.done_all,
                                    size: 12,
                                    color:
                                        colors.onPrimary.withValues(alpha: 0.7),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Message input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              top: BorderSide(
                color: colors.outline.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Attachment Button
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: colors.primary),
                  onPressed: () {
                    // Show attachment options (Mock)
                    _showAttachmentOptions(context, colors);
                  },
                  tooltip: 'Add Attachment',
                ),
                // Emoji Button
                IconButton(
                  icon: Icon(Icons.sentiment_satisfied_alt,
                      color: colors.primary),
                  onPressed: () {
                    // Show emoji picker (Mock/Placeholder)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Emoji picker coming soon!')),
                    );
                  },
                  tooltip: 'Add Emoji',
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor:
                          colors.surfaceContainerHighest.withValues(alpha: 0.5),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(chatId, room),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _sendMessage(chatId, room),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.send, color: colors.onPrimary, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAttachmentOptions(BuildContext context, ColorScheme colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentItem(Icons.image, 'Images', colors,
                    () => Navigator.pop(context)),
                _buildAttachmentItem(Icons.insert_drive_file, 'Files', colors,
                    () => Navigator.pop(context)),
                _buildAttachmentItem(Icons.camera_alt, 'Camera', colors,
                    () => Navigator.pop(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(
      IconData icon, String label, ColorScheme colors, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  int _getCourseUnreadTotal() {
    int total = 0;
    for (var course in widget.enrolledCourses) {
      total += _unreadCounts['course_${course['id']}'] ?? 0;
    }
    return total;
  }

  int _getInstructorUnreadTotal() {
    int total = 0;
    for (var course in widget.enrolledCourses) {
      total += _unreadCounts['instructor_${course['id']}'] ?? 0;
    }
    return total;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildPaywallScreen({
    required IconData icon,
    required String title,
    required String message,
    required ThemeData theme,
    required ColorScheme colors,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lock icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock,
                size: 80,
                color: Colors.red.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),

            // Category icon
            Icon(
              icon,
              size: 48,
              color: colors.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Action button
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to billing section
                // This would ideally trigger a callback to parent widget
                // to switch to billing view
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                        'Please navigate to Billing section to make payment'),
                    action: SnackBarAction(
                      label: 'Dismiss',
                      onPressed: () {},
                    ),
                    duration: const Duration(seconds: 5),
                  ),
                );
              },
              icon: const Icon(Icons.payment),
              label: const Text('Go to Billing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Help text
            Text(
              'Community chat remains accessible',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String userId;
  final String userName;
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.userId,
    required this.userName,
    required this.message,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Unknown',
      message: json['message'] ?? '',
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}
