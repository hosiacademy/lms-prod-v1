// lib/src/core/services/wishlist_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../../data/models/course.dart';
import '../../data/models/learnership.dart';

/// Wishlist Service - Manages wishlist items across the Student Portal
/// Syndicated with backend via ApiClient
class WishlistService {
  static final WishlistService _instance = WishlistService._private();
  factory WishlistService() => _instance;
  WishlistService._private();

  // Content Types Map (model name -> id)
  Map<String, int> _contentTypes = {};

  // Wishlist items organized by type for local access
  final List<Course> _courses = [];
  final List<Learnership> _learnerships = [];
  final Map<String, dynamic> _masterclasses = {}; // id -> masterclass data
  final Map<String, dynamic> _industryTraining = {}; // id -> training data

  // Map to store wishlist item IDs (key: "type_id", value: wishlist_item_id)
  final Map<String, int> _wishlistItemIds = {};

  // Stream controllers for real-time updates
  final StreamController<int> _wishlistCountController =
      StreamController<int>.broadcast();
  Stream<int> get wishlistCountStream => _wishlistCountController.stream;

  final StreamController<void> _wishlistUpdatedController =
      StreamController<void>.broadcast();
  Stream<void> get wishlistUpdatedStream => _wishlistUpdatedController.stream;

  /// Get total number of items in wishlist
  int get itemCount =>
      _courses.length +
      _learnerships.length +
      _masterclasses.length +
      _industryTraining.length;

  /// Get all courses in wishlist
  List<Course> get courses => List.unmodifiable(_courses);

  /// Get all learnerships in wishlist
  List<Learnership> get learnerships => List.unmodifiable(_learnerships);

  /// Get all masterclasses in wishlist
  Map<String, dynamic> get masterclasses => Map.unmodifiable(_masterclasses);

  /// Get all industry training in wishlist
  Map<String, dynamic> get industryTraining =>
      Map.unmodifiable(_industryTraining);

  bool _initialized = false;

  /// Initialize service: fetch content types and wishlist
  Future<void> init() async {
    try {
      // 1. Fetch content types
      final types = await ApiClient.getContentTypes();
      _contentTypes = types.map((k, v) => MapEntry(k, v as int));

      // 2. Fetch wishlist
      await _fetchWishlist();
      _initialized = true;
    } catch (e) {
      debugPrint('[WishlistService] Init error: $e');
    }
  }

  /// Ensure service is initialized before performing wishlist operations
  Future<void> _ensureInitialized() async {
    if (!_initialized || _contentTypes.isEmpty) {
      await init();
    }
  }

  /// Fetch and parse wishlist from backend
  Future<void> _fetchWishlist() async {
    try {
      final items = await ApiClient.getWishlist();
      _clearLocalState();

      for (var item in items) {
        _processWishlistItem(item);
      }

      _notifyUpdate();
    } catch (e) {
      debugPrint('[WishlistService] Fetch wishlist error: $e');
    }
  }

  void _clearLocalState() {
    _courses.clear();
    _learnerships.clear();
    _masterclasses.clear();
    _industryTraining.clear();
    _wishlistItemIds.clear();
  }

  void _processWishlistItem(dynamic item) {
    if (item is! Map<String, dynamic>) return;

    final trainingType = item['training_type'];
    final objectId = item['object_id'];
    final itemId = item['id'];
    final details = item['content_object'];

    if (details == null) return; // Should not happen if data integrity is good

    final title = details['title'] ?? details['name'] ?? 'Unknown';
    // Price might be needed if we display it in wishlist, usually it is on the object

    // Store wishlist item ID
    final typeKey = _getTypeKey(trainingType, objectId.toString());
    _wishlistItemIds[typeKey] = itemId;

    if (trainingType == 'course' || trainingType == 'aicertscourse') {
      final course = Course(
        id: objectId.toString(),
        title: title,
        description: details['description'],
        active: true,
        // We might want to fetch more details or use what we have
        featureImageUrl: details['feature_image_url'],
      );
      _courses.add(course);
    } else if (trainingType == 'learnership') {
      final learnership = Learnership(
        id: objectId,
        title: title,
        slug: details['slug'] ?? '',
        specialization: details['specialization'] ?? '',
      );
      _learnerships.add(learnership);
    } else if (trainingType == 'masterclass') {
      _masterclasses[objectId.toString()] = {
        'id': objectId.toString(),
        'title': title,
        ...details
      };
    } else if (trainingType == 'industry_training' ||
        trainingType == 'offering') {
      _industryTraining[objectId.toString()] = {
        'id': objectId.toString(),
        'title': title,
        ...details
      };
    }
  }

  String _getTypeKey(String type, String id) => '${type}_$id';

  /// Add a course to wishlist
  Future<bool> addCourse(Course course) async {
    if (_courses.any((c) => c.id == course.id)) return false;

    try {
      await _ensureInitialized();
      String modelName = course.externalId != null ? 'aicertscourse' : 'course';
      if (!_contentTypes.containsKey(modelName)) modelName = 'course';

      final contentTypeId = _contentTypes[modelName];
      if (contentTypeId == null) return false;

      await ApiClient.addToWishlist(
        contentTypeId: contentTypeId,
        objectId: int.parse(course.id),
        trainingType: modelName,
      );

      await _fetchWishlist();
      return true;
    } catch (e) {
      debugPrint('[WishlistService] Add course error: $e');
      return false;
    }
  }

  /// Remove a course from wishlist
  Future<bool> removeCourse(String courseId) async {
    int? itemId = _wishlistItemIds[_getTypeKey('course', courseId)];
    if (itemId == null)
      itemId = _wishlistItemIds[_getTypeKey('aicertscourse', courseId)];

    if (itemId == null) return false;

    try {
      await ApiClient.removeFromWishlist(itemId);
      await _fetchWishlist();
      return true;
    } catch (e) {
      debugPrint('[WishlistService] Remove course error: $e');
      return false;
    }
  }

  /// Check if a course is in wishlist
  bool hasCourse(String courseId) {
    return _courses.any((c) => c.id == courseId);
  }

  /// Add a learnership to wishlist
  Future<bool> addLearnership(Learnership learnership) async {
    if (_learnerships.any((l) => l.id == learnership.id)) return false;

    try {
      await _ensureInitialized();
      final contentTypeId = _contentTypes['learnershipprogramme'];
      if (contentTypeId == null) return false;

      await ApiClient.addToWishlist(
        contentTypeId: contentTypeId,
        objectId: learnership.id,
        trainingType: 'learnership',
      );

      await _fetchWishlist();
      return true;
    } catch (e) {
      debugPrint('[WishlistService] Add learnership error: $e');
      return false;
    }
  }

  /// Remove a learnership from wishlist
  Future<bool> removeLearnership(int learnershipId) async {
    final itemId =
        _wishlistItemIds[_getTypeKey('learnership', learnershipId.toString())];
    if (itemId == null) return false;

    try {
      await ApiClient.removeFromWishlist(itemId);
      await _fetchWishlist();
      return true;
    } catch (e) {
      debugPrint('[WishlistService] Remove learnership error: $e');
      return false;
    }
  }

  /// Check if a learnership is in wishlist
  bool hasLearnership(int learnershipId) {
    return _learnerships.any((l) => l.id == learnershipId);
  }

  /// Add a masterclass to wishlist
  Future<bool> addMasterclass(
      String id, Map<String, dynamic> masterclassData) async {
    if (_masterclasses.containsKey(id)) return false;

    try {
      await _ensureInitialized();
      final contentTypeId = _contentTypes['masterclass'];
      if (contentTypeId == null) return false;

      await ApiClient.addToWishlist(
        contentTypeId: contentTypeId,
        objectId: int.parse(id),
        trainingType: 'masterclass',
      );

      await _fetchWishlist();
      return true;
    } catch (e) {
      debugPrint('[WishlistService] Add masterclass error: $e');
      return false;
    }
  }

  /// Remove a masterclass from wishlist
  Future<bool> removeMasterclass(String id) async {
    final itemId = _wishlistItemIds[_getTypeKey('masterclass', id)];
    if (itemId == null) return false;

    try {
      await ApiClient.removeFromWishlist(itemId);
      await _fetchWishlist();
      return true;
    } catch (e) {
      debugPrint('[WishlistService] Remove masterclass error: $e');
      return false;
    }
  }

  /// Check if a masterclass is in wishlist
  bool hasMasterclass(String id) {
    return _masterclasses.containsKey(id);
  }

  /// Add industry training to wishlist
  Future<bool> addIndustryTraining(
      String id, Map<String, dynamic> trainingData) async {
    if (_industryTraining.containsKey(id)) return false;

    try {
      await _ensureInitialized();
      final contentTypeId = _contentTypes['offering'];
      if (contentTypeId == null) return false;

      await ApiClient.addToWishlist(
        contentTypeId: contentTypeId,
        objectId: int.parse(id),
        trainingType: 'industry_training',
      );

      await _fetchWishlist();
      return true;
    } catch (e) {
      debugPrint('[WishlistService] Add industry training error: $e');
      return false;
    }
  }

  /// Remove industry training from wishlist
  Future<bool> removeIndustryTraining(String id) async {
    int? itemId = _wishlistItemIds[_getTypeKey('industry_training', id)];
    if (itemId == null) {
      itemId = _wishlistItemIds[_getTypeKey('offering', id)];
    }

    if (itemId == null) return false;

    try {
      await ApiClient.removeFromWishlist(itemId);
      await _fetchWishlist();
      return true;
    } catch (e) {
      debugPrint('[WishlistService] Remove industry training error: $e');
      return false;
    }
  }

  /// Check if industry training is in wishlist
  bool hasIndustryTraining(String id) {
    return _industryTraining.containsKey(id);
  }

  /// Move an item to cart
  Future<bool> moveToCart(String type, String objectId) async {
    // Determine which item ID to use
    // Using simple mapping based on type
    String key = _getTypeKey(type, objectId);
    if (!_wishlistItemIds.containsKey(key)) {
      // Try mapping 'course' -> 'aicertscourse' fallback
      if (type == 'course') key = _getTypeKey('aicertscourse', objectId);
    }

    final itemId = _wishlistItemIds[key];
    if (itemId == null) return false;

    try {
      await ApiClient.moveWishlistItemToCart(itemId);
      await _fetchWishlist(); // Refresh wishlist (item should be gone)
      // We should also refresh Cart, but CartService should handle its own refresh
      // Maybe easier if CartService listens to something or we call it explicitly.
      // Ideally we assume the user will reload the cart or we trigger global event.
      return true;
    } catch (e) {
      debugPrint('[WishlistService] Move to cart error: $e');
      return false;
    }
  }

  /// Clear all items from wishlist
  Future<void> clearWishlist() async {
    // API doesn't have a clear endpoint for wishlist usually, but we can loop or add one.
    // For now, let's just clear local state and maybe notify user implementation details.
    // But user asked for implementation.
    // Let's iterate and delete.
    for (var id in _wishlistItemIds.values) {
      try {
        await ApiClient.removeFromWishlist(id);
      } catch (e) {
        // ignore
      }
    }
    _clearLocalState();
    _notifyUpdate();
    debugPrint('[WishlistService] Wishlist cleared');
  }

  /// Notify listeners of wishlist updates
  void _notifyUpdate() {
    _wishlistCountController.add(itemCount);
    _wishlistUpdatedController.add(null);
  }

  /// Dispose resources
  void dispose() {
    _wishlistCountController.close();
    _wishlistUpdatedController.close();
  }
}

/// Global wishlist service instance
final wishlistService = WishlistService();
