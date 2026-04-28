import 'package:flutter/material.dart';
import '../../data/models/course.dart';

class CartProvider extends ChangeNotifier {
  final List<Course> _cartItems = [];
  final List<Course> _wishlistItems = [];

  List<Course> get cartItems => List.unmodifiable(_cartItems);
  List<Course> get wishlistItems => List.unmodifiable(_wishlistItems);

  int get cartCount => _cartItems.length;
  int get wishlistCount => _wishlistItems.length;

  double get totalPrice => _cartItems.fold(0, (sum, item) => sum + (item.price ?? 0));

  bool isInCart(String courseId) => _cartItems.any((item) => item.id == courseId);
  bool isWishlisted(String courseId) => _wishlistItems.any((item) => item.id == courseId);

  void addToCart(Course course) {
    if (!isInCart(course.id)) {
      _cartItems.add(course.copyWith(isInCart: true));
      notifyListeners();
    }
  }

  void removeFromCart(String courseId) {
    _cartItems.removeWhere((item) => item.id == courseId);
    notifyListeners();
  }

  void toggleWishlist(Course course) {
    if (isWishlisted(course.id)) {
      _wishlistItems.removeWhere((item) => item.id == course.id);
    } else {
      _wishlistItems.add(course.copyWith(isWishlisted: true));
    }
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}
