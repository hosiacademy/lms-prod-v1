// lib/src/core/services/cart_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../services/auth_service.dart';
import '../../data/models/course.dart';
import '../../data/models/learnership.dart';

/// Course Cart Service - Manages cart items across the Student Portal
/// Syndicated with backend via ApiClient
class CartService {
  static final CartService _instance = CartService._private();
  factory CartService() => _instance;
  CartService._private();

  // Cart ID from backend
  int? _cartId;

  // Content Types Map (model name -> id)
  Map<String, int> _contentTypes = {};

  // Cart items organized by type for local access
  final List<Course> _courses = [];
  final List<Learnership> _learnerships = [];
  final Map<String, dynamic> _masterclasses = {}; // id -> masterclass data
  final Map<String, dynamic> _industryTraining = {}; // id -> training data

  // Map to store cart item IDs (object_id -> item_id)
  final Map<String, int> _cartItemIds =
      {}; // key: "type_id", value: cart_item_id

  // Stream controllers for real-time updates
  final StreamController<int> _cartCountController =
      StreamController<int>.broadcast();
  Stream<int> get cartCountStream => _cartCountController.stream;

  final StreamController<void> _cartUpdatedController =
      StreamController<void>.broadcast();
  Stream<void> get cartUpdatedStream => _cartUpdatedController.stream;

  /// Get total number of items in cart
  int get itemCount =>
      _courses.length +
      _learnerships.length +
      _masterclasses.length +
      _industryTraining.length;

  /// Get all courses in cart
  List<Course> get courses => List.unmodifiable(_courses);

  /// Get all learnerships in cart
  List<Learnership> get learnerships => List.unmodifiable(_learnerships);

  /// Get all masterclasses in cart
  Map<String, dynamic> get masterclasses => Map.unmodifiable(_masterclasses);

  /// Get all industry training in cart
  Map<String, dynamic> get industryTraining =>
      Map.unmodifiable(_industryTraining);

  /// Initialize service: fetch content types and active cart
  Future<void> init() async {
    try {
      // 1. Fetch content types
      final types = await ApiClient.getContentTypes();
      _contentTypes = types.map((k, v) => MapEntry(k, v as int));

      // 2. Fetch active cart if authenticated
      final token = await AuthService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        await _fetchCart();
      } else {
        await _loadLocalCart();
      }
    } catch (e) {
      debugPrint('[CartService] Init error: $e');
      await _loadLocalCart(); // Fallback to local on error
    }
  }

  /// Sync local cart with backend after login
  Future<void> sync() async {
    final token = await AuthService.getAccessToken();
    if (token == null || token.isEmpty) return;

    if (_courses.isEmpty && _learnerships.isEmpty) {
      await _fetchCart();
      return;
    }

    // Capture local state
    final localCourses = List<Course>.from(_courses);

    // Refresh cart from server
    await _fetchCart();

    // Add local items to server cart if not already there
    for (var course in localCourses) {
      if (!hasCourse(course.id)) {
        await addCourse(course);
      }
    }

    // Clear local storage after successful sync
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('offline_cart_courses');
  }

  Future<void> _loadLocalCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coursesJson = prefs.getStringList('offline_cart_courses') ?? [];

      _courses.clear();
      for (var jsonStr in coursesJson) {
        try {
          _courses.add(Course.fromJson(jsonDecode(jsonStr)));
        } catch (e) {
          debugPrint('Error decoding local course: $e');
        }
      }
      _notifyUpdate();
    } catch (e) {
      debugPrint('[CartService] Load local cart error: $e');
    }
  }

  Future<void> _saveLocalCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coursesJson = _courses.map((c) => jsonEncode(c.toJson())).toList();
      await prefs.setStringList('offline_cart_courses', coursesJson);
    } catch (e) {
      debugPrint('[CartService] Save local cart error: $e');
    }
  }

  /// Fetch and parse active cart from backend
  Future<void> _fetchCart() async {
    try {
      final cartData = await ApiClient.getActiveCart();
      _cartId = cartData['id'];

      _clearLocalState();

      if (cartData['items'] != null) {
        final items = cartData['items'] as List;
        for (var item in items) {
          _processCartItem(item);
        }
      }

      _notifyUpdate();
    } catch (e) {
      debugPrint('[CartService] Fetch cart error: $e');
    }
  }

  void _clearLocalState() {
    _courses.clear();
    _learnerships.clear();
    _masterclasses.clear();
    _industryTraining.clear();
    _cartItemIds.clear();
  }

  void _processCartItem(Map<String, dynamic> item) {
    final trainingType = item['training_type'];
    final objectId = item['object_id'];
    final itemId = item['id']; // Cart item ID
    final details = item['course_details'];
    final title = item['course_title'] ?? 'Unknown';
    final price = item['price'];
    final formattedPrice = item['formatted_price'];

    // Store cart item ID mapping
    final typeKey = _getTypeKey(trainingType, objectId.toString());
    _cartItemIds[typeKey] = itemId;

    // Reconstruct objects based on type
    if (trainingType == 'course' || trainingType == 'aicertscourse') {
      final course = Course(
        id: objectId.toString(),
        title: title,
        description: details?['description'],
        durationHours: details?['duration'] is int ? details['duration'] : null,
        active: true,
        localPrice: price?.toString(), // Already localized from backend
        localCurrency: item['currency'],
      );
      _courses.add(course);
    } else if (trainingType == 'learnership') {
      // Create minimal Learnership object
      final learnership = Learnership(
        id: objectId,
        title: title,
        slug: '',
        specialization: '',
        price: price != null ? double.tryParse(price.toString()) : null,
        currency: item['currency'],
      );
      _learnerships.add(learnership);
    } else if (trainingType == 'masterclass') {
      _masterclasses[objectId.toString()] = {
        'id': objectId.toString(),
        'title': title,
        'price': price,
        'formatted_price': formattedPrice,
        ...details ?? {}
      };
    } else if (trainingType == 'industry_training' ||
        trainingType == 'offering') {
      _industryTraining[objectId.toString()] = {
        'id': objectId.toString(),
        'title': title,
        'price': price,
        'formatted_price': formattedPrice,
        ...details ?? {}
      };
    }
  }

  String _getTypeKey(String type, String id) => '${type}_$id';

  /// Add a course to cart
  Future<bool> addCourse(Course course) async {
    if (hasCourse(course.id)) return false;

    try {
      final token = await AuthService.getAccessToken();
      final isAuthenticated = token != null && token.isNotEmpty;

      if (!isAuthenticated) {
        // Guest mode: Save locally
        _courses.add(course);
        await _saveLocalCart();
        _notifyUpdate();
        return true;
      }

      if (_cartId == null) await _fetchCart();
      if (_cartId == null) {
        // Fallback to local if server cart fetch failed
        _courses.add(course);
        await _saveLocalCart();
        _notifyUpdate();
        return true;
      }

      // Determine content type (aicertscourse or course)
      String modelName = course.externalId != null ? 'aicertscourse' : 'course';
      if (!_contentTypes.containsKey(modelName)) modelName = 'course';

      final contentTypeId = _contentTypes[modelName];
      if (contentTypeId == null) return false;

      // Parse numeric ID (Aicerts courses use 'aicerts_ID' format in the frontend)
      int? objectId;
      if (course.externalId != null) {
        objectId = int.tryParse(course.externalId!);
      }

      if (objectId == null) {
        final idStr = course.id.replaceAll('aicerts_', '');
        objectId = int.tryParse(idStr);
      }

      if (objectId == null) {
        debugPrint('[CartService] Invalid course ID: ${course.id}');
        return false;
      }

      await ApiClient.addToCart(
        cartId: _cartId!,
        contentTypeId: contentTypeId,
        objectId: objectId,
        trainingType: modelName,
      );

      // Refresh cart to get full details and IDs
      await _fetchCart();
      return true;
    } catch (e) {
      debugPrint('[CartService] Add course error: $e');

      // Secondary fallback on server error
      if (!hasCourse(course.id)) {
        _courses.add(course);
        await _saveLocalCart();
        _notifyUpdate();
        return true;
      }
      return false;
    }
  }

  /// Remove a course from cart
  Future<bool> removeCourse(String courseId) async {
    try {
      final token = await AuthService.getAccessToken();
      final isAuthenticated = token != null && token.isNotEmpty;

      if (!isAuthenticated) {
        // Guest mode: Remove locally
        final initialLength = _courses.length;
        _courses.removeWhere((c) => c.id == courseId);
        if (_courses.length < initialLength) {
          await _saveLocalCart();
          _notifyUpdate();
          return true;
        }
        return false;
      }

      // Try both course types to find the item. Normalizing the prefix.
      String strippedId = courseId.replaceAll('aicerts_', '');

      int? itemId = _cartItemIds[_getTypeKey('course', strippedId)];
      if (itemId == null) {
        itemId = _cartItemIds[_getTypeKey('aicertscourse', strippedId)];
      }

      // Fallback: Try exact courseId string
      if (itemId == null) {
        itemId = _cartItemIds[_getTypeKey('course', courseId)];
      }
      if (itemId == null) {
        itemId = _cartItemIds[_getTypeKey('aicertscourse', courseId)];
      }

      if (itemId == null) {
        // Fallback if item ID isn't found but local course exists
        final initialLength = _courses.length;
        _courses.removeWhere((c) => c.id == courseId);
        if (_courses.length < initialLength) {
          _notifyUpdate();
          return true;
        }
        return false;
      }

      await ApiClient.removeFromCart(_cartId!, itemId);
      await _fetchCart();
      return true;
    } catch (e) {
      debugPrint('[CartService] Remove course error: $e');
      // Secondary fallback on server error
      final initialLength = _courses.length;
      _courses.removeWhere((c) => c.id == courseId);
      if (_courses.length < initialLength) {
        _notifyUpdate();
        return true;
      }
      return false;
    }
  }

  /// Check if a course is in cart
  bool hasCourse(String courseId) {
    if (_courses.any((c) => c.id == courseId)) return true;

    // Also check stripped id (for AICERTS)
    final strippedId = courseId.replaceAll('aicerts_', '');
    if (strippedId != courseId) {
      if (_courses.any((c) => c.id == strippedId)) return true;
    }

    // Also check with `aicerts_` prefix
    if (!courseId.startsWith('aicerts_')) {
      if (_courses.any((c) => c.id == 'aicerts_$courseId')) return true;
    }

    return false;
  }

  /// Add a learnership to cart
  Future<bool> addLearnership(Learnership learnership) async {
    if (_learnerships.any((l) => l.id == learnership.id)) return false;

    try {
      if (_cartId == null) await _fetchCart();
      if (_cartId == null) return false;

      final contentTypeId = _contentTypes['learnershipprogramme'];
      if (contentTypeId == null) return false;

      await ApiClient.addToCart(
        cartId: _cartId!,
        contentTypeId: contentTypeId,
        objectId: learnership.id,
        trainingType: 'learnership',
      );

      await _fetchCart();
      return true;
    } catch (e) {
      debugPrint('[CartService] Add learnership error: $e');
      return false;
    }
  }

  /// Remove a learnership from cart
  Future<bool> removeLearnership(int learnershipId) async {
    final itemId =
        _cartItemIds[_getTypeKey('learnership', learnershipId.toString())];
    if (itemId == null) return false;

    try {
      await ApiClient.removeFromCart(_cartId!, itemId);
      await _fetchCart();
      return true;
    } catch (e) {
      debugPrint('[CartService] Remove learnership error: $e');
      return false;
    }
  }

  /// Check if a learnership is in cart
  bool hasLearnership(int learnershipId) {
    return _learnerships.any((l) => l.id == learnershipId);
  }

  /// Add a masterclass to cart
  Future<bool> addMasterclass(
      String id, Map<String, dynamic> masterclassData) async {
    if (_masterclasses.containsKey(id)) return false;

    try {
      if (_cartId == null) await _fetchCart();
      if (_cartId == null) return false;

      final contentTypeId = _contentTypes['masterclass'];
      if (contentTypeId == null) return false;

      await ApiClient.addToCart(
        cartId: _cartId!,
        contentTypeId: contentTypeId,
        objectId: int.parse(id),
        trainingType: 'masterclass',
      );

      await _fetchCart();
      return true;
    } catch (e) {
      debugPrint('[CartService] Add masterclass error: $e');
      return false;
    }
  }

  /// Remove a masterclass from cart
  Future<bool> removeMasterclass(String id) async {
    final itemId = _cartItemIds[_getTypeKey('masterclass', id)];
    if (itemId == null) return false;

    try {
      await ApiClient.removeFromCart(_cartId!, itemId);
      await _fetchCart();
      return true;
    } catch (e) {
      debugPrint('[CartService] Remove masterclass error: $e');
      return false;
    }
  }

  /// Check if a masterclass is in cart
  bool hasMasterclass(String id) {
    return _masterclasses.containsKey(id);
  }

  /// Add industry training to cart
  Future<bool> addIndustryTraining(
      String id, Map<String, dynamic> trainingData) async {
    if (_industryTraining.containsKey(id)) return false;

    try {
      if (_cartId == null) await _fetchCart();
      if (_cartId == null) return false;

      final contentTypeId =
          _contentTypes['offering']; // 'offering' for industry training
      if (contentTypeId == null) return false;

      await ApiClient.addToCart(
        cartId: _cartId!,
        contentTypeId: contentTypeId,
        objectId: int.parse(id),
        trainingType: 'industry_training',
      );

      await _fetchCart();
      return true;
    } catch (e) {
      debugPrint('[CartService] Add industry training error: $e');
      return false;
    }
  }

  /// Remove industry training from cart
  Future<bool> removeIndustryTraining(String id) async {
    final itemId = _cartItemIds[_getTypeKey('industry_training', id)];
    // Try 'offering' as fallback key just in case
    if (itemId == null && _cartItemIds.containsKey('offering_$id')) {
      // ...
    }

    if (itemId == null) return false;

    try {
      await ApiClient.removeFromCart(_cartId!, itemId);
      await _fetchCart();
      return true;
    } catch (e) {
      debugPrint('[CartService] Remove industry training error: $e');
      return false;
    }
  }

  /// Check if industry training is in cart
  bool hasIndustryTraining(String id) {
    return _industryTraining.containsKey(id);
  }

  /// Clear all items from cart
  Future<void> clearCart() async {
    try {
      final token = await AuthService.getAccessToken();
      final isAuthenticated = token != null && token.isNotEmpty;

      _clearLocalState();

      if (!isAuthenticated) {
        await _saveLocalCart();
        _notifyUpdate();
        return;
      }

      if (_cartId != null) {
        await ApiClient.clearCart(_cartId!);
        await _fetchCart(); // confirm clear
      }
    } catch (e) {
      debugPrint('[CartService] Clear cart error: $e');
    }
  }

  /// Proceed to checkout
  Future<Map<String, dynamic>?> checkout(
      {bool usePreviousDetails = false, bool isCorporate = false}) async {
    if (_cartId == null) return null;
    try {
      return await ApiClient.checkoutCart(
        cartId: _cartId!,
        usePreviousDetails: usePreviousDetails,
        isCorporate: isCorporate,
      );
    } catch (e) {
      debugPrint('[CartService] Checkout error: $e');
      return null;
    }
  }

  /// Calculate total price of items in cart
  double calculateTotal() {
    double total = 0.0;
    // Iterate through all lists and sum up
    // Note: This relies on local state which is synced from backend
    // Backend provides total_amount on the cart object, but we are calculating locally here for UI speed
    // Ideally we should use the total from backend response

    for (var course in _courses) {
      if (course.localPrice != null) {
        final cleanPrice = course.localPrice!.replaceAll(RegExp(r'[^\d.]'), '');
        total += double.tryParse(cleanPrice) ?? course.price ?? 0.0;
      } else {
        total += course.price ?? 0.0;
      }
    }
    for (var item in _learnerships) {
      total += item.price ?? 0.0;
    }
    for (var item in _masterclasses.values) {
      total += (item['price'] as num?)?.toDouble() ?? 0.0;
    }
    for (var item in _industryTraining.values) {
      total += (item['price'] as num?)?.toDouble() ?? 0.0;
    }

    return total;
  }

  /// Get currency (assumes all items use same currency)
  String getCurrency() {
    if (_courses.isNotEmpty) return _courses.first.localCurrency ?? 'USD';
    if (_learnerships.isNotEmpty) return _learnerships.first.currency ?? 'USD';
    return 'USD';
  }

  /// Notify listeners of cart updates
  void _notifyUpdate() {
    _cartCountController.add(itemCount);
    _cartUpdatedController.add(null);
  }

  /// Dispose resources
  void dispose() {
    _cartCountController.close();
    _cartUpdatedController.close();
  }
}

/// Global cart service instance
final cartService = CartService();
