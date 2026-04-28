# Socket.IO Frontend Integration Guide

## Connection Configuration

### Production URLs
- **Backend API + Socket.IO:** `http://154.66.211.3:7001` or `https://your-domain:7005`
- **Frontend:** `http://154.66.211.3:7000` or `https://your-domain`

### Development URLs
- **Backend API + Socket.IO:** `http://localhost:7001`
- **Frontend:** `http://localhost:3000` or `http://localhost:5555`

## Flutter Integration

### 1. Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  socket_io_client: ^2.0.3
  shared_preferences: ^2.2.2
```

### 2. Socket Service

```dart
// lib/services/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  String? _authToken;

  // Connection
  void connect(String baseUrl, String authToken) {
    _authToken = authToken;
    
    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .disableAutoConnect()
        .setExtraHeaders({'Authorization': 'Bearer $authToken'})
        .build(),
    );

    // Connect with auth token
    _socket!.connect(auth: {'token': authToken});

    // Connection events
    _socket!.onConnect((_) {
      print('✅ Connected to Socket.IO server');
      _socket!.emit('presence_online', {'userId': _getCurrentUserId()});
    });

    _socket!.onDisconnect((_) => print('❌ Disconnected'));

    _socket!.onConnectError((data) => print('Connection error: $data'));

    // Message events
    _socket!.on('message', (data) {
      print('📩 New message: $data');
      // Handle incoming message
      _handleIncomingMessage(data);
    });

    // Presence events
    _socket!.on('user_online', (data) {
      print('🟢 User online: ${data['username']}');
    });

    _socket!.on('user_offline', (data) {
      print('⚫ User offline: ${data['username']}');
    });

    // Typing indicators
    _socket!.on('typing_indicator', (data) {
      print('⌨️ Typing: ${data['username']}');
    });

    // Read receipts
    _socket!.on('messages_read', (data) {
      print('✓ Messages read in chat: ${data['chatId']}');
    });
  }

  // Join chat rooms
  void joinRoom(String roomId) {
    _socket!.emit('join_room', {'room': roomId});
    print('Joined room: $roomId');
  }

  // Get user's chat rooms
  void getChatRooms() {
    _socket!.emit('get_chat_rooms');
    _socket!.on('chat_rooms_list', (data) {
      print('📋 Chat rooms: ${data['rooms']}');
      // Auto-join all rooms
      for (var room in data['rooms']) {
        joinRoom(room['id'] ?? room);
      }
      // Join community room
      joinRoom('community_global');
    });
  }

  // Send message
  void sendMessage({
    required String chatId,
    required String content,
    int? receiverId,
  }) {
    _socket!.emit('send_message', {
      'chatId': chatId,
      'content': content,
      'receiverId': receiverId,
    });
  }

  // Typing indicator
  void sendTypingIndicator(String chatId, bool isTyping) {
    _socket!.emit('typing', {
      'chatId': chatId,
      'isTyping': isTyping,
    });
  }

  // Mark messages as read
  void markAsRead(String messageId, String chatId) {
    _socket!.emit('mark_as_read', {
      'messageId': messageId,
      'chatId': chatId,
    });
  }

  // Get online users
  void getOnlineUsers() {
    _socket!.emit('get_online_users');
    _socket!.on('online_users', (data) {
      print('👥 Online users: ${data['users']}');
    });
  }

  // Update presence
  void updatePresence(String status, {String? customStatus}) {
    _socket!.emit('presence_update', {
      'status': status,
      'customStatus': customStatus,
    });
  }

  // Disconnect
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    // Implement your message handling logic
  }

  String _getCurrentUserId() {
    // Extract from token or stored user data
    return 'current_user_id';
  }
}
```

### 3. Usage Example

```dart
// In your dashboard or app initialization
import 'package:your_app/services/socket_service.dart';

class ChatDashboard extends StatefulWidget {
  @override
  _ChatDashboardState createState() => _ChatDashboardState();
}

class _ChatDashboardState extends State<ChatDashboard> {
  final _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  Future<void> _initializeSocket() async {
    // Get auth token from secure storage
    final authToken = await _getAuthToken();
    
    // Connect to Socket.IO
    _socketService.connect('http://154.66.211.3:7001', authToken);
    
    // Get and join chat rooms
    _socketService.getChatRooms();
    _socketService.getOnlineUsers();
  }

  void _sendMessageToStudent(int studentId, String message) {
    _socketService.sendMessage(
      chatId: 'direct_${_currentUserId}_$studentId',
      content: message,
      receiverId: studentId,
    );
  }

  void _sendCourseMessage(int courseId, String message) {
    _socketService.sendMessage(
      chatId: 'course_learnership_$courseId',
      content: message,
    );
  }

  void _sendCommunityMessage(String message) {
    _socketService.sendMessage(
      chatId: 'community_global',
      content: message,
    );
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }
}
```

## React Integration

### 1. Install Dependencies

```bash
npm install socket.io-client
```

### 2. Socket Service

```javascript
// src/services/socketService.js
import { io } from 'socket.io-client';

class SocketService {
  constructor() {
    this.socket = null;
    this.baseUrl = process.env.REACT_APP_SOCKET_URL || 'http://localhost:7001';
  }

  connect(authToken) {
    this.socket = io(this.baseUrl, {
      auth: { token: authToken },
      transports: ['websocket', 'polling'],
      reconnection: true,
      reconnectionDelay: 1000,
      reconnectionAttempts: 5,
    });

    // Connection events
    this.socket.on('connect', () => {
      console.log('✅ Connected to Socket.IO server');
      this.socket.emit('presence_online', { userId: this.getCurrentUserId() });
    });

    this.socket.on('disconnect', () => {
      console.log('❌ Disconnected');
    });

    this.socket.on('connect_error', (error) => {
      console.error('Connection error:', error);
    });

    // Message events
    this.socket.on('message', (data) => {
      console.log('📩 New message:', data);
      this.handleIncomingMessage(data);
    });

    // Presence events
    this.socket.on('user_online', (data) => {
      console.log('🟢 User online:', data.username);
    });

    this.socket.on('user_offline', (data) => {
      console.log('⚫ User offline:', data.username);
    });

    // Typing indicators
    this.socket.on('typing_indicator', (data) => {
      console.log('⌨️ Typing:', data.username);
    });

    // Read receipts
    this.socket.on('messages_read', (data) => {
      console.log('✓ Messages read:', data.chatId);
    });

    return this.socket;
  }

  // Join chat rooms
  joinRoom(roomId) {
    this.socket.emit('join_room', { room: roomId });
    console.log('Joined room:', roomId);
  }

  // Get user's chat rooms
  getChatRooms() {
    this.socket.emit('get_chat_rooms');
    this.socket.on('chat_rooms_list', (data) => {
      console.log('📋 Chat rooms:', data.rooms);
      // Auto-join all rooms
      data.rooms.forEach(room => {
        this.joinRoom(room.id || room);
      });
      // Join community room
      this.joinRoom('community_global');
    });
  }

  // Send message
  sendMessage({ chatId, content, receiverId }) {
    this.socket.emit('send_message', {
      chatId,
      content,
      receiverId,
    });
  }

  // Typing indicator
  sendTypingIndicator(chatId, isTyping) {
    this.socket.emit('typing', {
      chatId,
      isTyping,
    });
  }

  // Mark messages as read
  markAsRead(messageId, chatId) {
    this.socket.emit('mark_as_read', {
      messageId,
      chatId,
    });
  }

  // Get online users
  getOnlineUsers() {
    this.socket.emit('get_online_users');
    this.socket.on('online_users', (data) => {
      console.log('👥 Online users:', data.users);
    });
  }

  // Update presence
  updatePresence(status, customStatus = null) {
    this.socket.emit('presence_update', {
      status,
      customStatus,
    });
  }

  // Disconnect
  disconnect() {
    if (this.socket) {
      this.socket.disconnect();
      this.socket = null;
    }
  }

  handleIncomingMessage(data) {
    // Implement your message handling logic
  }

  getCurrentUserId() {
    // Extract from token or stored user data
    return 'current_user_id';
  }
}

export default new SocketService();
```

### 3. React Hook

```javascript
// src/hooks/useSocket.js
import { useEffect, useState, useCallback } from 'react';
import socketService from '../services/socketService';

export function useSocket() {
  const [isConnected, setIsConnected] = useState(false);
  const [onlineUsers, setOnlineUsers] = useState([]);
  const [chatRooms, setChatRooms] = useState([]);

  useEffect(() => {
    const handleConnect = () => setIsConnected(true);
    const handleDisconnect = () => setIsConnected(false);
    const handleOnlineUsers = (data) => setOnlineUsers(data.users);
    const handleChatRooms = (data) => setChatRooms(data.rooms);

    socketService.socket?.on('connect', handleConnect);
    socketService.socket?.on('disconnect', handleDisconnect);
    socketService.socket?.on('online_users', handleOnlineUsers);
    socketService.socket?.on('chat_rooms_list', handleChatRooms);

    return () => {
      socketService.socket?.off('connect', handleConnect);
      socketService.socket?.off('disconnect', handleDisconnect);
      socketService.socket?.off('online_users', handleOnlineUsers);
      socketService.socket?.off('chat_rooms_list', handleChatRooms);
    };
  }, []);

  const sendMessage = useCallback(({ chatId, content, receiverId }) => {
    socketService.sendMessage({ chatId, content, receiverId });
  }, []);

  const joinRoom = useCallback((roomId) => {
    socketService.joinRoom(roomId);
  }, []);

  return {
    isConnected,
    onlineUsers,
    chatRooms,
    sendMessage,
    joinRoom,
    socket: socketService.socket,
  };
}
```

### 4. Usage Example

```javascript
// src/components/ChatDashboard.jsx
import React, { useEffect } from 'react';
import { useSocket } from '../hooks/useSocket';
import socketService from '../services/socketService';

function ChatDashboard() {
  const { isConnected, sendMessage, joinRoom } = useSocket();

  useEffect(() => {
    // Initialize socket on mount
    const authToken = localStorage.getItem('authToken');
    socketService.connect(authToken);
    socketService.getChatRooms();

    return () => {
      socketService.disconnect();
    };
  }, []);

  const handleSendToStudent = (studentId, message) => {
    sendMessage({
      chatId: `direct_${currentUserId}_${studentId}`,
      content: message,
      receiverId: studentId,
    });
  };

  const handleSendToCourse = (courseId, message) => {
    sendMessage({
      chatId: `course_learnership_${courseId}`,
      content: message,
    });
  };

  const handleSendToCommunity = (message) => {
    sendMessage({
      chatId: 'community_global',
      content: message,
    });
  };

  return (
    <div>
      <div>Status: {isConnected ? '✅ Connected' : '❌ Disconnected'}</div>
      {/* Your chat UI components */}
    </div>
  );
}

export default ChatDashboard;
```

## Chat Room ID Formats

| Chat Type | Room ID Format | Example |
|-----------|---------------|---------|
| One-on-One | `direct_{user1}_{user2}` | `direct_10_25` |
| Course | `course_learnership_{id}` | `course_learnership_5` |
| Community | `community_global` | `community_global` |
| Database Room | `chat_{room_id}` | `chat_123` |

## Event Reference

### Client → Server Events

| Event | Payload | Description |
|-------|---------|-------------|
| `join_room` | `{ room: string }` | Join a chat room |
| `get_chat_rooms` | - | Get user's chat rooms |
| `send_message` | `{ chatId, content, receiverId? }` | Send a message |
| `typing` | `{ chatId, isTyping: boolean }` | Typing indicator |
| `mark_as_read` | `{ messageId, chatId }` | Mark messages as read |
| `get_online_users` | - | Get list of online users |
| `presence_update` | `{ status, customStatus? }` | Update user presence |
| `presence_online` | `{ userId }` | Mark user as online |

### Server → Client Events

| Event | Payload | Description |
|-------|---------|-------------|
| `message` | Message object | New message received |
| `chat_rooms_list` | `{ rooms: [] }` | List of user's chat rooms |
| `user_online` | `{ userId, username, role }` | User came online |
| `user_offline` | `{ userId }` | User went offline |
| `typing_indicator` | `{ chatId, username, isTyping }` | Typing indicator |
| `messages_read` | `{ chatId, userId }` | Messages marked as read |
| `online_users` | `{ users: [] }` | List of online users |
| `welcome` | `{ message, userId }` | Welcome message on connect |

## Testing

### Manual Test with Browser Console

```javascript
// Connect
const socket = io('http://154.66.211.3:7001', {
  auth: { token: 'YOUR_JWT_TOKEN' }
});

// Listen for events
socket.on('connect', () => console.log('Connected!'));
socket.on('message', (data) => console.log('Message:', data));

// Join a room
socket.emit('join_room', { room: 'community_global' });

// Send a message
socket.emit('send_message', {
  chatId: 'community_global',
  content: 'Hello from browser console!'
});
```
