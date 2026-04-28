// order_models.dart - ALIGNED WITH UPDATED PAYMENT_ENUMS
import 'package:flutter/material.dart';
import 'payment_enums.dart';
import '../../../../core/services/currency_service.dart';

class OrderItem {
  final String courseId;
  final String courseTitle;
  final String? courseImage;
  final String? instructorName;
  final double price;
  final double? discount;
  final double finalPrice;
  final int quantity;

  OrderItem({
    required this.courseId,
    required this.courseTitle,
    this.courseImage,
    this.instructorName,
    required this.price,
    this.discount,
    required this.finalPrice,
    this.quantity = 1,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      courseId: json['course_id'] ?? json['masterclass_id'] ?? '',
      courseTitle: json['course_title'] ?? json['masterclass_title'] ?? '',
      courseImage: json['course_image'],
      instructorName: json['instructor_name'],
      price: (json['price'] ?? json['unit_price'] ?? 0.0).toDouble(),
      discount: (json['discount'] ?? 0.0).toDouble(),
      finalPrice:
          (json['final_price'] ?? json['total_amount'] ?? 0.0).toDouble(),
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'course_title': courseTitle,
      'course_image': courseImage,
      'instructor_name': instructorName,
      'price': price,
      'discount': discount,
      'final_price': finalPrice,
      'quantity': quantity,
    };
  }
}

class Order {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String? userPhone;
  final String? userCountry;
  final List<OrderItem> items;
  final double subtotal;
  final double? discount;
  final double tax;
  final double total;
  final String currency;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? paidAt;
  final String? transactionId;
  final String? notes;
  final String? paymentProvider;
  final bool isCorporate;
  final String? companyName;

  Order({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.userPhone,
    this.userCountry,
    required this.items,
    required this.subtotal,
    this.discount,
    required this.tax,
    required this.total,
    this.currency = 'USD',
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.paidAt,
    this.transactionId,
    this.notes,
    this.paymentProvider,
    this.isCorporate = false,
    this.companyName,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Parse payment method - try value first, then enum name
    PaymentMethod paymentMethod;
    if (json['payment_method'] is String) {
      final methodString = json['payment_method'] as String;
      try {
        // Try to parse from value (e.g., 'credit_card')
        paymentMethod = PaymentMethod.fromValue(methodString);
      } catch (e) {
        // Fallback to enum name (e.g., 'creditCard')
        paymentMethod = PaymentMethod.values.firstWhere(
          (e) => e.toString().split('.').last == methodString,
          orElse: () => PaymentMethod.creditCard,
        );
      }
    } else {
      paymentMethod = PaymentMethod.creditCard;
    }

    // Parse payment status - try value first, then enum name
    PaymentStatus status;
    if (json['status'] is String) {
      final statusString = json['status'] as String;
      try {
        // Try to parse from value (e.g., 'pending')
        status = PaymentStatus.fromValue(statusString);
      } catch (e) {
        // Fallback to enum name (e.g., 'pending')
        status = PaymentStatus.values.firstWhere(
          (e) => e.toString().split('.').last == statusString,
          orElse: () => PaymentStatus.pending,
        );
      }
    } else {
      status = PaymentStatus.pending;
    }

    return Order(
      id: json['id'] ?? json['order_id'] ?? '',
      userId: json['user_id'] ?? '',
      userEmail: json['user_email'] ?? json['email'] ?? '',
      userName: json['user_name'] ?? json['name'] ?? '',
      userPhone: json['user_phone'] ?? json['phone'],
      userCountry: json['user_country'] ?? json['country'],
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      discount: (json['discount'] ?? 0.0).toDouble(),
      tax: (json['tax'] ?? 0.0).toDouble(),
      total: (json['total'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      paymentMethod: paymentMethod,
      status: status,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      paidAt:
          json['paid_at'] != null ? DateTime.tryParse(json['paid_at']) : null,
      transactionId: json['transaction_id'],
      notes: json['notes'],
      paymentProvider: json['payment_provider'],
      isCorporate: json['is_corporate'] ?? false,
      companyName: json['company_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_email': userEmail,
      'user_name': userName,
      'user_phone': userPhone,
      'user_country': userCountry,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'currency': currency,
      'payment_method':
          paymentMethod.value, // Use .value instead of .toString()
      'status': status.value, // Use .value instead of .toString()
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'transaction_id': transactionId,
      'notes': notes,
      'payment_provider': paymentProvider,
      'is_corporate': isCorporate,
      'company_name': companyName,
    };
  }

  // Getters
  bool get isPaid => status.isSuccessful;
  bool get isPending => status.isPending;
  bool get isFailed => status.isFailed;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get formattedTotal {
    return CurrencyService.instance.formatPrice(total, currencyCode: currency);
  }

  String get paymentMethodDisplay => paymentMethod.displayName;
  String get statusDisplay => status.displayName;
  Color get statusColor => status.color;
  IconData get paymentMethodIcon => paymentMethod.icon;

  // Check if payment method is mobile money
  bool get isMobileMoneyPayment => paymentMethod.isMobileMoney;

  // Check if payment method is card
  bool get isCardPayment => paymentMethod.isCard;

  // Check if payment method is bank transfer
  bool get isBankTransferPayment => paymentMethod.isBankTransfer;

  // Check if payment method is digital wallet
  bool get isDigitalWalletPayment => paymentMethod.isDigitalWallet;

  // Get discount percentage
  double? get discountPercentage {
    if (discount == null || discount == 0 || subtotal == 0) return null;
    return ((discount! / subtotal) * 100);
  }

  // Get tax percentage
  double get taxPercentage {
    if (tax == 0 || subtotal == 0) return 0;
    return ((tax / subtotal) * 100);
  }
}

// Extension for Order list operations
extension OrderListExtension on List<Order> {
  List<Order> get pendingOrders => where((order) => order.isPending).toList();
  List<Order> get paidOrders => where((order) => order.isPaid).toList();
  List<Order> get failedOrders => where((order) => order.isFailed).toList();

  List<Order> getCorporateOrders({bool corporate = true}) =>
      where((order) => order.isCorporate == corporate).toList();

  double get totalRevenue => fold(0.0, (sum, order) => sum + order.total);

  List<Order> getOrdersByStatus(PaymentStatus status) =>
      where((order) => order.status == status).toList();

  List<Order> getOrdersByPaymentMethod(PaymentMethod method) =>
      where((order) => order.paymentMethod == method).toList();

  List<Order> getRecentOrders({int days = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return where((order) => order.createdAt.isAfter(cutoffDate)).toList();
  }
}
