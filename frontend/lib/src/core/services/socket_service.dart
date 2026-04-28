// lib/src/core/services/socket_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Global socket service instance (singleton pattern)
final socketService = SocketService();

class SocketService {
  // Private constructor
  SocketService._private();

  // Singleton instance
  static final SocketService _instance = SocketService._private();
  factory SocketService() => _instance;

  // ───────────────────────────────────────
  // Public streams expected by your dashboard
  // ───────────────────────────────────────
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  final StreamController<dynamic> _messageController =
      StreamController<dynamic>.broadcast();
  Stream<dynamic> get messageStream => _messageController.stream;

  final StreamController<Map<String, dynamic>> _presenceController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get presenceStream => _presenceController.stream;

  // Current connection state
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Initialize socket connection
  void initialize({required String userId}) {
    debugPrint('🔌 [SocketService] Initializing for user: $userId');

    // Simulate successful connection after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      _isConnected = true;
      _connectionController.add(true);
      debugPrint('✅ [SocketService] Connected');
    });

    // Simulate some incoming messages/presence for demo
    _simulateIncomingData();
  }

  /// Simulate real socket events (for UI testing while backend is down)
  void _simulateIncomingData() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!_messageController.isClosed) {
        _messageController.add({
          'type': 'chat',
          'chatId': 'chat-001',
          'content': 'Hey! How are you doing?',
          'senderName': 'Dr. Smith',
        });
      }
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (!_presenceController.isClosed) {
        _presenceController.add({
          'userId': 'instructor-001',
          'status': 'online',
        });
      }
    });
  }

  /// Send presence update (online/away/offline)
  void updatePresence(UserStatus status) {
    debugPrint('📡 [SocketService] Presence update: ${status.name}');
    // In real app: send via socket
    // For now: just broadcast locally
    _presenceController.add({
      'userId': 'current-user',
      'status': status.name,
    });
  }

  /// Disconnect and clean up
  void disconnect() {
    _isConnected = false;
    _connectionController.add(false);
    debugPrint('❌ [SocketService] Disconnected');
  }

  /// Clean up streams
  void dispose() {
    _connectionController.close();
    _messageController.close();
    _presenceController.close();
  }
}

/// Enum used in dashboard (must match your models)
enum UserStatus { online, away, offline }
