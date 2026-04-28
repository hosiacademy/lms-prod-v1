// lib/src/presentation/widgets/chat/staff_chat_panel.dart
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../core/config/environment.dart';
import '../../../core/api/api_client.dart';

/// Chat Panel for all Admin Staff roles.
///
/// Tab 1 — Community: hosi_academy_community room (all users)
/// Tab 2 — Staff:     staff_group_chat (all admins+instructors) +
///                    searchable 1-on-1 DMs selected by name or designation
class StaffChatPanel extends StatefulWidget {
  final String userId;
  final String userName;
  final String userDesignation; // e.g. "Marketing Administrator • South Africa"
  final Function(int)? onUnreadCountChange;

  const StaffChatPanel({
    super.key,
    required this.userId,
    required this.userName,
    this.userDesignation = 'Administrator',
    this.onUnreadCountChange,
  });

  @override
  State<StaffChatPanel> createState() => _StaffChatPanelState();
}

class _StaffChatPanelState extends State<StaffChatPanel>
    with SingleTickerProviderStateMixin {
  late IO.Socket _socket;
  late TabController _tabs;

  // Messages & controllers keyed by room/chatId
  final Map<String, List<_ChatMsg>> _messages = {};
  final Map<String, TextEditingController> _inputs = {};
  final Map<String, int> _unread = {};

  // Staff DM sub-state
  List<Map<String, dynamic>> _staffList = [];
  bool _loadingStaff = false;
  String _staffSearch = '';
  String? _activeDmId; // chatId of open 1-on-1
  String? _activeDmName;

  // Which staff sub-view: 'group' | 'dm_list' | 'dm_chat'
  String _staffSubView = 'group';

  bool _isConnected = false;

  static const String _community = 'hosi_academy_community';
  static const String _staffGroup = 'staff_group_chat';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _initRoom(_community);
    _initRoom(_staffGroup);
    _initSocket();
    _loadStaffDirectory();
  }

  void _initRoom(String id) {
    _messages[id] ??= [];
    _inputs[id] ??= TextEditingController();
    _unread[id] ??= 0;
  }

  void _initSocket() {
    _socket = IO.io(Environment.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': Environment.socketReconnection,
      'timeout': Environment.socketTimeout,
      'auth': {
        'userId': widget.userId,
        'userName': widget.userName,
        'role': 'admin',
      },
    });

    _socket.onConnect((_) {
      if (mounted) setState(() => _isConnected = true);
      _socket.emit('join_room', {'room': _community});
      _socket.emit('join_room', {'room': _staffGroup, 'role': 'admin'});
    });

    _socket.onDisconnect((_) {
      if (mounted) setState(() => _isConnected = false);
    });

    _socket.on('message', _onMessage);

    if (Environment.socketEnabled) {
      try {
        _socket.connect();
      } catch (_) {}
    }
  }

  void _onMessage(dynamic data) {
    if (data is! Map) return;
    final raw = (data['message'] ?? data) as Map;
    final room = raw['chatId']?.toString() ?? raw['room']?.toString() ?? _community;
    final msg = _ChatMsg(
      id: raw['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: raw['senderId']?.toString() ?? '',
      senderName: raw['senderName']?.toString() ?? 'Unknown',
      content: raw['content']?.toString() ?? raw['message']?.toString() ?? '',
      timestamp: DateTime.tryParse(raw['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
    setState(() {
      _messages.putIfAbsent(room, () => []);
      _messages[room]!.add(msg);
      if (room != (_activeDmId ?? (_staffSubView == 'group' ? _staffGroup : _community))) {
        _unread[room] = (_unread[room] ?? 0) + 1;
        _broadcastTotal();
      }
    });
  }

  void _broadcastTotal() {
    final total = _unread.values.fold(0, (a, b) => a + b);
    widget.onUnreadCountChange?.call(total);
  }

  Future<void> _loadStaffDirectory({String? query}) async {
    setState(() => _loadingStaff = true);
    try {
      final list = await ApiClient.getStaffDirectory(searchQuery: query);
      if (mounted) setState(() => _staffList = list);
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingStaff = false);
    }
  }

  void _openDm(Map<String, dynamic> member) {
    final dmRoom = member['dm_room_id'] as String;
    _initRoom(dmRoom);
    if (!(_messages[dmRoom]?.isNotEmpty ?? false)) {
      _socket.emit('join_room', {'room': dmRoom, 'role': 'admin'});
    }
    setState(() {
      _activeDmId = dmRoom;
      _activeDmName = member['name'] as String?;
      _staffSubView = 'dm_chat';
      _unread[dmRoom] = 0;
    });
  }

  void _send(String roomId) {
    final ctrl = _inputs[roomId];
    if (ctrl == null || ctrl.text.trim().isEmpty) return;
    final content = ctrl.text.trim();
    final msg = {
      'chatId': roomId,
      'content': content,
      'senderId': widget.userId,
      'senderName': widget.userName,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _socket.emit('send_message', msg);
    setState(() {
      _messages[roomId]!.add(_ChatMsg(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: widget.userId,
        senderName: widget.userName,
        content: content,
        timestamp: DateTime.now(),
      ));
    });
    ctrl.clear();
  }

  int get _communityUnread => _unread[_community] ?? 0;
  int get _staffUnread {
    int t = _unread[_staffGroup] ?? 0;
    for (final k in _unread.keys) {
      if (k.startsWith('staff_dm_')) t += _unread[k] ?? 0;
    }
    return t;
  }

  @override
  void dispose() {
    _tabs.dispose();
    _socket
      ..off('message')
      ..disconnect()
      ..dispose();
    for (final c in _inputs.values) c.dispose();
    super.dispose();
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(children: [
      _buildHeader(theme, colors),
      TabBar(
        controller: _tabs,
        labelColor: colors.primary,
        unselectedLabelColor: colors.onSurface.withOpacity(0.6),
        indicatorColor: colors.primary,
        indicatorWeight: 3,
        tabs: [
          Tab(
            icon: Badge(
              isLabelVisible: _communityUnread > 0,
              label: Text('$_communityUnread'),
              child: const Icon(Icons.public),
            ),
            text: 'Community',
          ),
          Tab(
            icon: Badge(
              isLabelVisible: _staffUnread > 0,
              label: Text('$_staffUnread'),
              child: const Icon(Icons.badge),
            ),
            text: 'Staff',
          ),
        ],
      ),
      Expanded(
        child: TabBarView(
          controller: _tabs,
          children: [
            _buildChatView(_community, theme, colors),
            _buildStaffTab(theme, colors),
          ],
        ),
      ),
    ]);
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outline.withOpacity(0.15))),
      ),
      child: Row(children: [
        Icon(Icons.chat_bubble_rounded, color: colors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text('Staff Comms',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: _isConnected ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(_isConnected ? 'Live' : 'Offline',
            style: theme.textTheme.labelSmall?.copyWith(
              color: _isConnected ? Colors.green : Colors.red,
            )),
      ]),
    );
  }

  // ─── Staff Tab ────────────────────────────────────────────────────────────

  Widget _buildStaffTab(ThemeData theme, ColorScheme colors) {
    switch (_staffSubView) {
      case 'dm_list':
        return _buildDmList(theme, colors);
      case 'dm_chat':
        return _buildDmChat(theme, colors);
      default:
        return _buildStaffGroup(theme, colors);
    }
  }

  Widget _buildStaffGroup(ThemeData theme, ColorScheme colors) {
    return Column(children: [
      // Sub-nav: Group Chat | 1-on-1
      Container(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: null, // already here
              icon: const Icon(Icons.groups, size: 16),
              label: const Text('Group Chat'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _staffSubView = 'dm_list'),
              icon: const Icon(Icons.person_search, size: 16),
              label: const Text('1-on-1'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ]),
      ),
      Expanded(child: _buildChatView(_staffGroup, theme, colors,
          subtitle: 'All administrators & instructors')),
    ]);
  }

  Widget _buildDmList(ThemeData theme, ColorScheme colors) {
    return Column(children: [
      // Top bar
      Padding(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _staffSubView = 'group'),
          ),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or designation...',
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: colors.surfaceContainerHighest.withOpacity(0.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                isDense: true,
              ),
              onChanged: (v) {
                _staffSearch = v;
                _loadStaffDirectory(query: v.isEmpty ? null : v);
              },
            ),
          ),
        ]),
      ),
      if (_loadingStaff)
        const Expanded(child: Center(child: CircularProgressIndicator()))
      else if (_staffList.isEmpty)
        Expanded(
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.people_outline, size: 48, color: colors.onSurface.withOpacity(0.3)),
              const SizedBox(height: 12),
              Text(_staffSearch.isEmpty ? 'No staff found' : 'No matches for "$_staffSearch"',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface.withOpacity(0.5))),
            ]),
          ),
        )
      else
        Expanded(
          child: ListView.builder(
            itemCount: _staffList.length,
            itemBuilder: (_, i) {
              final m = _staffList[i];
              final name = m['name'] as String? ?? 'Staff';
              final designation = m['designation'] as String? ?? m['role_label'] as String? ?? '';
              final dmRoom = m['dm_room_id'] as String? ?? '';
              final unread = _unread[dmRoom] ?? 0;

              // Color-code by role
              Color roleColor = colors.primary;
              if (m['role'] == 'instructor') roleColor = Colors.teal;
              if (m['role'] == 'executive_admin') roleColor = Colors.purple;
              if (m['role'] == 'hr_admin') roleColor = Colors.orange;

              return ListTile(
                leading: Stack(clipBehavior: Clip.none, children: [
                  CircleAvatar(
                    backgroundColor: roleColor.withOpacity(0.15),
                    backgroundImage: (m['avatar_url'] as String?)?.isNotEmpty == true
                        ? NetworkImage(m['avatar_url'] as String)
                        : null,
                    child: (m['avatar_url'] as String?)?.isNotEmpty != true
                        ? Text(name[0].toUpperCase(), style: TextStyle(color: roleColor, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  if (m['is_online'] == true)
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: Colors.green, shape: BoxShape.circle,
                          border: Border.all(color: colors.surface, width: 1.5),
                        ),
                      ),
                    ),
                ]),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(designation, style: TextStyle(fontSize: 11, color: roleColor)),
                trailing: unread > 0
                    ? CircleAvatar(radius: 10, backgroundColor: colors.error,
                        child: Text('$unread', style: TextStyle(color: colors.onError, fontSize: 10)))
                    : const Icon(Icons.chevron_right, size: 18),
                onTap: () => _openDm(m),
              );
            },
          ),
        ),
    ]);
  }

  Widget _buildDmChat(ThemeData theme, ColorScheme colors) {
    final roomId = _activeDmId!;
    return Column(children: [
      // DM header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withOpacity(0.4),
          border: Border(bottom: BorderSide(color: colors.outline.withOpacity(0.15))),
        ),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() { _staffSubView = 'dm_list'; _activeDmId = null; }),
          ),
          CircleAvatar(radius: 14, backgroundColor: colors.primary.withOpacity(0.15),
              child: Text((_activeDmName ?? '?')[0].toUpperCase(),
                  style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_activeDmName ?? 'Staff', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text('Private — Staff DM', style: theme.textTheme.labelSmall?.copyWith(color: colors.primary)),
            ]),
          ),
        ]),
      ),
      Expanded(child: _buildChatView(roomId, theme, colors)),
    ]);
  }

  // ─── Shared chat view ─────────────────────────────────────────────────────

  Widget _buildChatView(String roomId, ThemeData theme, ColorScheme colors, {String? subtitle}) {
    final msgs = _messages[roomId] ?? [];
    final ctrl = _inputs.putIfAbsent(roomId, () => TextEditingController());

    return Column(children: [
      if (subtitle != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: [
            Icon(Icons.info_outline, size: 12, color: colors.primary),
            const SizedBox(width: 6),
            Text(subtitle, style: theme.textTheme.labelSmall?.copyWith(color: colors.primary)),
          ]),
        ),
      Expanded(
        child: msgs.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chat_bubble_outline, size: 48,
                      color: colors.onSurface.withOpacity(0.25)),
                  const SizedBox(height: 12),
                  Text('No messages yet', style: TextStyle(color: colors.onSurface.withOpacity(0.5))),
                ]),
              )
            : ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: msgs.length,
                itemBuilder: (_, i) {
                  final msg = msgs[msgs.length - 1 - i];
                  final isMe = msg.senderId == widget.userId;
                  return _buildBubble(msg, isMe, theme, colors);
                },
              ),
      ),
      _buildInput(roomId, ctrl, theme, colors),
    ]);
  }

  Widget _buildBubble(_ChatMsg msg, bool isMe, ThemeData theme, ColorScheme colors) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 270),
        decoration: BoxDecoration(
          color: isMe ? colors.primary : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(msg.senderName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.primary, fontWeight: FontWeight.bold, fontSize: 11,
                  )),
            ),
          Text(msg.content,
              style: TextStyle(
                color: isMe ? colors.onPrimary : colors.onSurface,
                fontSize: 13, height: 1.4,
              )),
          const SizedBox(height: 4),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(_fmtTime(msg.timestamp),
                style: TextStyle(
                  fontSize: 9,
                  color: isMe ? colors.onPrimary.withOpacity(0.7) : colors.onSurfaceVariant,
                )),
            if (isMe) ...[
              const SizedBox(width: 4),
              Icon(Icons.done_all, size: 11, color: colors.onPrimary.withOpacity(0.7)),
            ],
          ]),
        ]),
      ),
    );
  }

  Widget _buildInput(String roomId, TextEditingController ctrl, ThemeData theme, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outline.withOpacity(0.1))),
      ),
      child: SafeArea(
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: colors.surfaceContainerHighest.withOpacity(0.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                isDense: true,
              ),
              onSubmitted: (_) => _send(roomId),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => _send(roomId),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
              child: Icon(Icons.send, color: colors.onPrimary, size: 18),
            ),
          ),
        ]),
      ),
    );
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ChatMsg {
  final String id, senderId, senderName, content;
  final DateTime timestamp;
  const _ChatMsg({required this.id, required this.senderId, required this.senderName, required this.content, required this.timestamp});
}
