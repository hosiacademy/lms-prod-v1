// lib/src/core/services/chat_socket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../data/models/chat_message.dart';
import '../config/environment.dart';
import 'auth_service.dart';

/// Real Socket.IO Service for Chat
/// Connects to Django Socket.IO backend for real-time messaging
class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._private();
  factory ChatSocketService() => _instance;
  ChatSocketService._private();

  // Socket.IO instance
  IO.Socket? _socket;
  
  // Connection state
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String? _currentUserId;
  String? get currentUserId => _currentUserId;
  
  String? _currentUserName;
  String? get currentUserName => _currentUserName;

  // Stream controllers for real-time events
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get messageStream => _messageController.stream;

  final StreamController<Map<String, dynamic>> _presenceController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get presenceStream =>
      _presenceController.stream;

  final StreamController<Map<String, dynamic>> _typingController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;

  // Local message cache
  final Map<String, List<ChatMessage>> _messageCache = {};

  // Active chat rooms
  final Set<String> _joinedRooms = {};
  
  // Online users cache
  final Map<String, Map<String, dynamic>> _onlineUsers = {};

  /// Initialize connection with user ID and JWT token
  Future<void> connect(String userId, {String? jwtToken, String? userName}) async {
    if (_isConnected) {
      debugPrint('[ChatSocket] Already connected');
      return;
    }

    _currentUserId = userId;
    _currentUserName = userName ?? 'User';
    
    // Get JWT token if not provided
    String? token = jwtToken;
    if (token == null) {
      token = await AuthService.getToken();
    }

    debugPrint('[ChatSocket] Connecting for user: $userId with token: ${token != null ? "present" : "missing"}');

    try {
      // Initialize Socket.IO connection
      _socket = IO.io(
        Environment.socketUrl,
        <String, dynamic>{
          'transports': ['websocket'],
          'autoConnect': true,
          'reconnection': true,
          'reconnectionDelay': 1000,
          'reconnectionAttempts': 10,
          'timeout': Environment.socketTimeout,
          'auth': {
            'userId': userId,
            'userName': _currentUserName,
          },
          'extraHeaders': {
            if (token != null) 'Authorization': 'Bearer $token',
            'user-id': userId,
            'client-type': 'flutter-web',
          },
        },
      );

      // Set up event listeners
      _setupSocketListeners();
      
      // Connect
      _socket!.connect();

    } catch (e) {
      debugPrint('[ChatSocket] Connection error: $e');
      _isConnected = false;
      _connectionController.add(false);
    }
  }

  /// Set up Socket.IO event listeners
  void _setupSocketListeners() {
    if (_socket == null) return;

    // Connection successful
    _socket!.onConnect((_) {
      debugPrint('[ChatSocket] ✅ Connected to Socket.IO server');
      _isConnected = true;
      _connectionController.add(true);
      
      // Join user's personal room
      _socket!.emit('join_room', {'roomId': _currentUserId});
      
      // Get online users
      _socket!.emit('get_online_users', {});
    });

    // Connection lost
    _socket!.onDisconnect((_) {
      debugPrint('[ChatSocket] ❌ Disconnected from Socket.IO server');
      _isConnected = false;
      _connectionController.add(false);
    });

    // Connection error
    _socket!.onConnectError((error) {
      debugPrint('[ChatSocket] 🔴 Connection error: $error');
      _isConnected = false;
      _connectionController.add(false);
    });

    // Welcome message
    _socket!.on('welcome', (data) {
      debugPrint('[ChatSocket] Welcome: $data');
    });

    // Incoming private message
    _socket!.on('private_message', (data) {
      debugPrint('[ChatSocket] 📩 Received private message: $data');
      _handleIncomingMessage(data);
    });

    // Incoming community/course message
    _socket!.on('message_received', (data) {
      debugPrint('[ChatSocket] 📩 Received community message: $data');
      _handleIncomingMessage(data);
    });

    // Message sent acknowledgment
    _socket!.on('message_sent', (data) {
      debugPrint('[ChatSocket] ✓ Message sent confirmed: $data');
    });

    // Typing indicator
    _socket!.on('typing_indicator', (data) {
      debugPrint('[ChatSocket] ⌨️ Typing indicator: $data');
      if (!_typingController.isClosed) {
        _typingController.add(data);
      }
    });

    // User presence update
    _socket!.on('user_presence', (data) {
      debugPrint('[ChatSocket] 👤 Presence update: $data');
      if (!_presenceController.isClosed) {
        _presenceController.add(data);
      }
    });

    // User online
    _socket!.on('user_online', (data) {
      debugPrint('[ChatSocket] 🟢 User online: ${data['username']}');
      _onlineUsers[data['userId']] = {
        'username': data['username'],
        'status': 'online',
        'role': data['role'],
      };
    });

    // User offline
    _socket!.on('user_offline', (data) {
      debugPrint('[ChatSocket] 🔴 User offline: ${data['username']}');
      _onlineUsers[data['userId']] = {
        'username': data['username'],
        'status': 'offline',
        'lastSeen': data['timestamp'],
      };
    });

    // Online users list
    _socket!.on('online_users', (data) {
      debugPrint('[ChatSocket] 📋 Online users: ${data['users']}');
      final users = data['users'] as List? ?? [];
      for (var user in users) {
        _onlineUsers[user['user_id'].toString()] = {
          'username': user['user__username'],
          'status': user['status'],
          'lastSeen': user['last_seen'],
        };
      }
    });

    // Chat rooms list
    _socket!.on('chat_rooms_list', (data) {
      debugPrint('[ChatSocket] 🏠 Chat rooms: ${data['rooms']}');
    });

    // Messages read receipt
    _socket!.on('messages_read', (data) {
      debugPrint('[ChatSocket] ✓ Messages read: $data');
    });

    // Room joined
    _socket!.on('room_joined', (data) {
      debugPrint('[ChatSocket] 🚪 Joined room: ${data['roomId']}');
      _joinedRooms.add(data['roomId']);
    });

    // Room left
    _socket!.on('room_left', (data) {
      debugPrint('[ChatSocket] 🚪 Left room: ${data['roomId']}');
      _joinedRooms.remove(data['roomId']);
    });

    // Error
    _socket!.on('error', (data) {
      debugPrint('[ChatSocket] ⚠️ Error: $data');
    });
  }

  /// Handle incoming message from Socket.IO
  void _handleIncomingMessage(Map<String, dynamic> data) {
    try {
      final messageData = data['message'] as Map<String, dynamic>?;
      if (messageData == null) return;

      final message = ChatMessage(
        id: messageData['id'] ?? 'msg-${DateTime.now().millisecondsSinceEpoch}',
        chatRoomId: messageData['chatId'] ?? messageData['chat_room'],
        senderId: messageData['senderId'] ?? messageData['sender_id'].toString(),
        senderName: messageData['senderName'] ?? messageData['sender_name'] ?? 'User',
        content: messageData['content'] ?? messageData['message'] ?? '',
        type: MessageType.values.firstWhere(
          (t) => t.name == (messageData['type'] ?? 'text'),
          orElse: () => MessageType.text,
        ),
        timestamp: messageData['timestamp'] != null
            ? DateTime.parse(messageData['timestamp'])
            : DateTime.now(),
        isRead: messageData['isRead'] ?? messageData['seen'] ?? false,
        replyToId: messageData['replyToId'] ?? messageData['reply_to_id'],
        metadata: messageData['metadata'],
      );

      // Add to cache
      final roomId = message.chatRoomId;
      if (roomId != null) {
        _messageCache.putIfAbsent(roomId, () => []).add(message);
      }

      // Broadcast to listeners
      if (!_messageController.isClosed) {
        _messageController.add(message);
      }
    } catch (e) {
      debugPrint('[ChatSocket] Error handling message: $e');
    }
  }

  /// Join a chat room (community or direct)
  Future<void> joinRoom(String roomId, {ChatType? type}) async {
    if (!_isConnected || _socket == null) {
      debugPrint('[ChatSocket] Not connected. Cannot join room: $roomId');
      return;
    }

    if (_joinedRooms.contains(roomId)) {
      debugPrint('[ChatSocket] Already in room: $roomId');
      return;
    }

    debugPrint('[ChatSocket] Joining room: $roomId (type: ${type?.name})');
    
    // Emit join room event
    _socket!.emit('join_room', {
      'roomId': roomId.replaceFirst('chat_', ''),
      'type': type?.name ?? 'community',
    });
  }

  /// Leave a chat room
  void leaveRoom(String roomId) {
    if (!_joinedRooms.contains(roomId)) return;

    debugPrint('[ChatSocket] Leaving room: $roomId');

    // Emit leave room event
    _socket?.emit('leave_room', {
      'roomId': roomId.replaceFirst('chat_', ''),
    });

    _joinedRooms.remove(roomId);
  }

  /// Send a message to a chat room
  Future<void> sendMessage({
    required String roomId,
    required String content,
    MessageType type = MessageType.text,
    String? replyToId,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isConnected || _socket == null || _currentUserId == null) {
      debugPrint('[ChatSocket] Cannot send message: Not connected');
      return;
    }

    final messageId = 'msg-${DateTime.now().millisecondsSinceEpoch}-${_currentUserId}';
    
    final messageData = {
      'id': messageId,
      'chatId': roomId,
      'content': content,
      'type': type.name,
      'senderId': _currentUserId,
      'senderName': _currentUserName,
      'timestamp': DateTime.now().toIso8601String(),
      if (replyToId != null) 'replyToId': replyToId,
      if (metadata != null) 'metadata': metadata,
    };

    debugPrint('[ChatSocket] 📤 Sending message to $roomId: $content');

    // Emit send_message event to backend
    _socket!.emit('send_message', messageData);

    // Add to local cache immediately (optimistic update)
    _messageCache.putIfAbsent(roomId, () => []).add(ChatMessage(
      id: messageId,
      chatRoomId: roomId,
      senderId: _currentUserId!,
      senderName: _currentUserName ?? 'You',
      content: content,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
      replyToId: replyToId,
      metadata: metadata,
    ));
  }

  /// Send typing indicator
  void sendTypingIndicator(String roomId, bool isTyping) {
    if (!_isConnected || _socket == null) return;

    debugPrint('[ChatSocket] ⌨️ Typing indicator: $roomId = $isTyping');

    _socket!.emit('typing', {
      'chatId': roomId.replaceFirst('chat_', ''),
      'isTyping': isTyping,
    });
  }

  /// Mark messages as read
  void markAsRead(String roomId, {String? messageId}) {
    if (!_isConnected || _socket == null) return;

    debugPrint('[ChatSocket] ✓ Marking messages as read in $roomId');

    _socket!.emit('mark_as_read', {
      'chatId': roomId.replaceFirst('chat_', ''),
      if (messageId != null) 'messageId': messageId,
    });
  }

  /// Get online users
  Map<String, Map<String, dynamic>> getOnlineUsers() {
    return Map.unmodifiable(_onlineUsers);
  }

  /// Refresh online users list
  void refreshOnlineUsers() {
    if (!_isConnected || _socket == null) return;
    _socket!.emit('get_online_users', {});
  }

  /// Get messages for a room from cache
  List<ChatMessage> getMessages(String roomId) {
    return _messageCache[roomId] ?? [];
  }

  /// Clear message cache for a room
  void clearMessageCache(String roomId) {
    _messageCache.remove(roomId);
  }

  /// Disconnect from socket
  void disconnect() {
    if (!_isConnected || _socket == null) return;

    debugPrint('[ChatSocket] Disconnecting...');

    // Leave all rooms
    for (final roomId in _joinedRooms.toList()) {
      leaveRoom(roomId);
    }

    _socket!.disconnect();
    _socket!.dispose();
    _socket = null;
    
    _isConnected = false;
    _currentUserId = null;
    _currentUserName = null;
    _connectionController.add(false);
  }

  /// Clean up resources
  void dispose() {
    disconnect();
    _connectionController.close();
    _messageController.close();
    _presenceController.close();
    _typingController.close();
    _messageCache.clear();
    _joinedRooms.clear();
    _onlineUsers.clear();
  }
}

/// Global instance
final chatSocketService = ChatSocketService();
