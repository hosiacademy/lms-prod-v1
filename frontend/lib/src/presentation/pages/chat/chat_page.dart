import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../widgets/headers/dashboard_header.dart';
import '../../../data/models/chat_models.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String? initialRoomId;

  const ChatPage({super.key, this.initialRoomId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool _isLoadingRooms = true;
  bool _isLoadingMessages = false;
  List<ChatRoom> _rooms = [];
  ChatRoom? _activeRoom;
  List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // For new chat discovery
  List<ChatParticipant> _staffMembers = [];
  bool _isSearchingStaff = false;


  // Current User Data
  Map<String, dynamic>? _currentUser;
  bool _isAnnouncementMode = false;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final user = await AuthService.getCurrentUser();
    _currentUser = user != null
        ? {
            'id': user['id'],
            'email': user['email'],
            'name': user['name'],
            'role': user['role'],
            'roleId': user['role_id'] ??
                (user['role'] == 'admin' ? 1 : (user['role'] == 'instructor' ? 2 : 3)),
          }
        : null;
    await _loadRooms();
    if (widget.initialRoomId != null) {
      // Logic to set active room once loaded
    }
  }

  String _getUserDesignation() {
    final roleId = _currentUser?['roleId'];
    if (roleId == 1) return 'Administrator';
    if (roleId == 2) return 'Instructor';
    return 'Student';
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoadingRooms = true);
    try {
      final roomsData = await ApiClient.getChatRooms();
      setState(() {
        _rooms = roomsData.map((j) => ChatRoom.fromJson(j)).toList();
        _isLoadingRooms = false;

        // If initialRoomId provided, select it
        if (widget.initialRoomId != null) {
          _activeRoom =
              _rooms.where((r) => r.id == widget.initialRoomId).firstOrNull;
          if (_activeRoom != null) _loadMessages(_activeRoom!.id);
        } else if (_rooms.isNotEmpty && _activeRoom == null) {
          // Auto-select first room (HosiAcademy Community usually)
          _activeRoom = _rooms.first;
          _loadMessages(_activeRoom!.id);
        }
      });
    } catch (e) {
      debugPrint('Error loading chat rooms: $e');
      setState(() => _isLoadingRooms = false);
    }
  }

  Future<void> _loadMessages(String roomId) async {
    setState(() => _isLoadingMessages = true);
    try {
      final messagesData = await ApiClient.getChatMessages(roomId);
      setState(() {
        _messages = messagesData.map((j) => ChatMessage.fromJson(j)).toList();
        _isLoadingMessages = false;
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error loading messages: $e');
      setState(() => _isLoadingMessages = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _activeRoom == null) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      // Determine message type (Executive can send announcements)
      final isExecutive = _currentUser?['isExecutive'] ?? false;
      final type =
          (_isAnnouncementMode && isExecutive) ? 'announcement' : 'text';

      await ApiClient.sendMessage(
        roomId: _activeRoom!.id,
        content: content,
        type: type,
      );

      // Reload messages to show new one
      _loadMessages(_activeRoom!.id);
    } catch (e) {
      debugPrint('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'mp3', 'mp4', 'pdf'],
    );

    if (result != null) {
      // Logic to upload file and send as message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File upload starting...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: colors.surfaceContainer,
      body: Column(
        children: [
          DashboardHeader(
            userName: _currentUser?['name'] ?? 'User',
            userDesignation: _getUserDesignation(),
            isAdmin: _currentUser?['roleId'] == 1,
            showMenuButton: false,
            onLogout: () async {
              await AuthService.logout();
              if (context.mounted) context.go('/onboarding');
            },
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Row(
                  children: [
                    // Sidebar
                    if (!isMobile || _activeRoom == null)
                      SizedBox(
                        width: isMobile ? screenWidth : 350,
                        child: _buildRoomList(colors, theme),
                      ),

                    // Vertical Divider
                    if (!isMobile)
                      VerticalDivider(
                          width: 1, thickness: 1, color: colors.outlineVariant),

                    // Chat Area
                    if (!isMobile || _activeRoom != null)
                      Expanded(
                        child: _activeRoom == null
                            ? _buildNoRoomSelected(colors, theme)
                            : Column(
                                children: [
                                  // Chat Header
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      border: Border(
                                          bottom: BorderSide(
                                              color: colors.outlineVariant)),
                                    ),
                                    child: Row(
                                      children: [
                                        if (isMobile)
                                          IconButton(
                                            onPressed: () => setState(
                                                () => _activeRoom = null),
                                            icon: const Icon(Icons.arrow_back),
                                          ),
                                        _buildRoomAvatar(_activeRoom!, colors),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _activeRoom!.name,
                                                style: theme
                                                    .textTheme.titleLarge
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold),
                                              ),
                                              Text(
                                                _activeRoom!.description ??
                                                    '${_activeRoom!.participantCount} participants',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                        color: colors
                                                            .onSurfaceVariant),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Announcements / Executive features
                                  if (_currentUser?['isExecutive'] == true)
                                    _buildExecutiveTools(colors, theme),

                                  _buildMessageList(colors, theme),
                                  _buildMessageInput(colors, theme),
                                ],
                              ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveTools(ColorScheme colors, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer.withValues(alpha: 0.1),
        border: Border(
            bottom: BorderSide(color: colors.tertiary.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Icon(Icons.campaign_rounded, size: 20, color: colors.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXECUTIVE BROADCAST MODE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.tertiary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  _isAnnouncementMode
                      ? 'Messages will be broadcast to all members and sent via email.'
                      : 'Normal chat mode. Toggle to send an official announcement.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontSize: 10, color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAnnouncementMode,
            onChanged: (val) => setState(() => _isAnnouncementMode = val),
            activeColor: colors.tertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildRoomList(ColorScheme colors, ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            children: [
              Text(
                'Messages',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: _showNewChatDialog,
                icon: Icon(Icons.add_comment_rounded, color: colors.primary),
                tooltip: 'Start New Chat',
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingRooms
              ? const Center(child: CircularProgressIndicator())
              : _rooms.isEmpty
                  ? Center(
                      child: Text('No active chats',
                          style: TextStyle(color: colors.onSurfaceVariant)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: _rooms.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final room = _rooms[index];
                        final isSelected = _activeRoom?.id == room.id;
                        return _buildRoomTile(room, isSelected, colors, theme);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildRoomTile(
      ChatRoom room, bool isSelected, ColorScheme colors, ThemeData theme) {
    return InkWell(
      onTap: () {
        setState(() => _activeRoom = room);
        _loadMessages(room.id);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryContainer.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _buildRoomAvatar(room, colors),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                            color:
                                isSelected ? colors.primary : colors.onSurface,
                          ),
                        ),
                      ),
                      if (room.lastMessage != null)
                        Text(
                          room.lastMessageTime,
                          style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10, color: colors.onSurfaceVariant),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.lastMessage?.content ?? 'No messages yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? colors.onPrimaryContainer
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (room.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            room.unreadCount.toString(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomAvatar(ChatRoom room, ColorScheme colors) {
    IconData icon;
    Color color;

    switch (room.type) {
      case 'community':
        icon = Icons.public_rounded;
        color = Colors.blue;
        break;
      case 'group':
        icon = Icons.people_rounded;
        color = Colors.orange;
        break;
      case 'announcement':
        icon = Icons.campaign_rounded;
        color = Colors.red;
        break;
      default:
        icon = Icons.person_rounded;
        color = colors.primary;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildMessageList(ColorScheme colors, ThemeData theme) {
    return Expanded(
      child: _isLoadingMessages
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe =
                    message.senderId == _currentUser?['id']?.toString();
                return _buildMessageBubble(message, isMe, colors, theme);
              },
            ),
    );
  }

  Widget _buildMessageInput(ColorScheme colors, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _pickAttachment,
            icon: const Icon(Icons.attach_file_rounded),
            color: colors.primary,
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.small(
            onPressed: _sendMessage,
            elevation: 0,
            child: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      ChatMessage message, bool isMe, ColorScheme colors, ThemeData theme) {
    final isAnnouncement = message.type == 'announcement';

    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (!isMe)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.senderName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                if (message.senderIsExecutive) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: colors.tertiary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'EXEC',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isAnnouncement
                ? colors.tertiaryContainer
                : (isMe ? colors.primary : colors.surfaceContainerHighest),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMe ? 20 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 20),
            ),
            boxShadow: [
              if (isAnnouncement)
                BoxShadow(
                    color: colors.tertiary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 1),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isAnnouncement)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.campaign_rounded,
                          size: 16, color: colors.tertiary),
                      const SizedBox(width: 8),
                      Text(
                        'OFFICIAL ANNOUNCEMENT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colors.tertiary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                message.content,
                style: TextStyle(
                  color: isAnnouncement
                      ? colors.onTertiaryContainer
                      : (isMe ? Colors.white : colors.onSurface),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: TextStyle(
                      fontSize: 9,
                      color: (isAnnouncement
                              ? colors.onTertiaryContainer
                              : (isMe
                                  ? Colors.white70
                                  : colors.onSurfaceVariant))
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 12,
                      color: Colors.white70,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoRoomSelected(ColorScheme colors, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline_rounded,
                size: 80, color: colors.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            'Select a conversation',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose from your existing chats or start a new one.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showNewChatDialog,
            icon: const Icon(Icons.add_comment_rounded),
            label: const Text('Start New Conversation'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNewChatDialog() async {
    setState(() => _isSearchingStaff = true);
    try {
      final staffData = await ApiClient.getStaffMembers();
      _staffMembers =
          staffData.map((j) => ChatParticipant.fromJson(j)).toList();
      _isSearchingStaff = false;

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Start Direct Chat'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: _staffMembers.isEmpty
                ? const Center(child: Text('No other staff members found'))
                : ListView.builder(
                    itemCount: _staffMembers.length,
                    itemBuilder: (context, index) {
                      final staff = _staffMembers[index];
                      // Don't show myself
                      if (staff.id.toString() ==
                          _currentUser?['id']?.toString())
                        return const SizedBox.shrink();

                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(staff.name[0]),
                        ),
                        title: Text(staff.name),
                        subtitle: Text(
                            staff.roleId == 1 ? 'Administrator' : 'Instructor'),
                        onTap: () async {
                          Navigator.pop(context);
                          _startDirectChat(staff.id);
                        },
                      );
                    },
                  ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error fetching staff: $e');
      setState(() => _isSearchingStaff = false);
    }
  }

  Future<void> _startDirectChat(int userId) async {
    try {
      final result = await ApiClient.createDirectChat(userId);
      final newRoom = ChatRoom.fromJson(result);
      setState(() {
        if (!_rooms.any((r) => r.id == newRoom.id)) {
          _rooms.add(newRoom);
        }
        _activeRoom = newRoom;
      });
      _loadMessages(newRoom.id);
    } catch (e) {
      debugPrint('Error starting direct chat: $e');
    }
  }
}
