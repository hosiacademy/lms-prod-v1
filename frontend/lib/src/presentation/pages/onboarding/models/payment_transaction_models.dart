// payment_transaction_models.dart - ALIGNED WITH UPDATED PAYMENT_ENUMS
import 'package:flutter/material.dart';
import 'payment_enums.dart';
import '../../../core/services/currency_service.dart';

class PaymentTransaction {
  final String id;
  final String orderId;
  final String userId;
  final String userEmail;
  final String userName;
  final String? userPhone;
  final String? userCountry;
  final double amount;
  final String currency;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? reference;
  final String? providerReference;
  final String? receiptUrl;
  final String? notes;
  final String? gatewayResponse;
  final bool isRefunded;
  final double? refundAmount;
  final DateTime? refundedAt;
  final String? paymentProvider;
  final String? mobileNumber;
  final String? mobileProvider;
  final String? cardLastFour;
  final String? cardHolderName;
  final String? cardExpiry;
  final bool isCorporate;
  final String? companyName;

  // Course/masterclass details
  final List<Map<String, dynamic>>? courseDetails;

  PaymentTransaction({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.userPhone,
    this.userCountry,
    required this.amount,
    this.currency = 'USD',
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.reference,
    this.providerReference,
    this.receiptUrl,
    this.notes,
    this.gatewayResponse,
    this.isRefunded = false,
    this.refundAmount,
    this.refundedAt,
    this.paymentProvider,
    this.mobileNumber,
    this.mobileProvider,
    this.cardLastFour,
    this.cardHolderName,
    this.cardExpiry,
    this.isCorporate = false,
    this.companyName,
    this.courseDetails,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    // Parse payment method - try value first, then enum name
    PaymentMethod paymentMethod;
    if (json['payment_method'] is String) {
      final methodString = json['payment_method'] as String;
      try {
        paymentMethod = PaymentMethod.fromValue(methodString);
      } catch (e) {
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
        status = PaymentStatus.fromValue(statusString);
      } catch (e) {
        status = PaymentStatus.values.firstWhere(
          (e) => e.toString().split('.').last == statusString,
          orElse: () => PaymentStatus.pending,
        );
      }
    } else {
      status = PaymentStatus.pending;
    }

    return PaymentTransaction(
      id: json['id'] ?? json['transaction_id'] ?? '',
      orderId: json['order_id'] ?? '',
      userId: json['user_id'] ?? '',
      userEmail: json['user_email'] ?? json['email'] ?? '',
      userName: json['user_name'] ?? json['name'] ?? '',
      userPhone: json['user_phone'] ?? json['phone'],
      userCountry: json['user_country'] ?? json['country'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      paymentMethod: paymentMethod,
      status: status,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      reference: json['reference'],
      providerReference: json['provider_reference'],
      receiptUrl: json['receipt_url'],
      notes: json['notes'],
      gatewayResponse: json['gateway_response'],
      isRefunded: json['is_refunded'] ?? false,
      refundAmount: (json['refund_amount'] ?? 0.0).toDouble(),
      refundedAt: json['refunded_at'] != null
          ? DateTime.tryParse(json['refunded_at'])
          : null,
      paymentProvider: json['payment_provider'],
      mobileNumber: json['mobile_number'],
      mobileProvider: json['mobile_provider'],
      cardLastFour: json['card_last_four'],
      cardHolderName: json['card_holder_name'],
      cardExpiry: json['card_expiry'],
      isCorporate: json['is_corporate'] ?? false,
      companyName: json['company_name'],
      courseDetails: json['course_details'] != null
          ? List<Map<String, dynamic>>.from(json['course_details'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'user_id': userId,
      'user_email': userEmail,
      'user_name': userName,
      'user_phone': userPhone,
      'user_country': userCountry,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod.value,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'reference': reference,
      'provider_reference': providerReference,
      'receipt_url': receiptUrl,
      'notes': notes,
      'gateway_response': gatewayResponse,
      'is_refunded': isRefunded,
      'refund_amount': refundAmount,
      'refunded_at': refundedAt?.toIso8601String(),
      'payment_provider': paymentProvider,
      'mobile_number': mobileNumber,
      'mobile_provider': mobileProvider,
      'card_last_four': cardLastFour,
      'card_holder_name': cardHolderName,
      'card_expiry': cardExpiry,
      'is_corporate': isCorporate,
      'company_name': companyName,
      'course_details': courseDetails,
    };
  }

  // ─── Getters ──────────────────────────────────────────────

  bool get isSuccessful => status.isSuccessful;
  bool get isPending => status.isPending;
  bool get isFailed => status.isFailed;
  bool get isProcessing => status == PaymentStatus.processing;
  bool get isOnHold => status == PaymentStatus.onHold;
  bool get isDisputed => status == PaymentStatus.disputed;
  bool get isExpired => status == PaymentStatus.expired;
  bool get isCancelled => status == PaymentStatus.cancelled;
  bool get isRefundedStatus =>
      status == PaymentStatus.refunded ||
      status == PaymentStatus.partiallyRefunded;

  String get formattedAmount {
    return CurrencyService.instance.formatPrice(amount, currencyCode: currency);
  }

  String get formattedRefundAmount {
    if (refundAmount == null || refundAmount == 0) return '—';
    return CurrencyService.instance.formatPrice(refundAmount!, currencyCode: currency);
  }

  String get paymentMethodDisplay => paymentMethod.displayName;
  String get statusDisplay => status.displayName;
  Color get statusColor => status.color;
  IconData get paymentMethodIcon => paymentMethod.icon;

  bool get isMobileMoneyTransaction => paymentMethod.isMobileMoney;
  bool get isCardTransaction => paymentMethod.isCard;
  bool get isBankTransferTransaction => paymentMethod.isBankTransfer;
  bool get isDigitalWalletTransaction => paymentMethod.isDigitalWallet;

  String? get maskedCardNumber {
    if (cardLastFour == null || cardLastFour!.isEmpty) return null;
    return '**** **** **** $cardLastFour';
  }

  String? get maskedMobileNumber {
    if (mobileNumber == null || mobileNumber!.isEmpty) return null;
    if (mobileNumber!.length <= 4) return mobileNumber;
    final lastFour = mobileNumber!.substring(mobileNumber!.length - 4);
    return '*** *** $lastFour';
  }

  String get formattedCreatedAt {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  Duration get age {
    return DateTime.now().difference(createdAt);
  }

  String get ageDisplay {
    final age = this.age;
    if (age.inDays > 30) {
      final months = age.inDays ~/ 30;
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (age.inDays > 0) {
      return '${age.inDays} day${age.inDays > 1 ? 's' : ''} ago';
    } else if (age.inHours > 0) {
      return '${age.inHours} hour${age.inHours > 1 ? 's' : ''} ago';
    } else if (age.inMinutes > 0) {
      return '${age.inMinutes} minute${age.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Check if transaction is recent (within 24 hours)
  bool get isRecent => age.inHours < 24;

  // Check if transaction is overdue (pending for more than 7 days)
  bool get isOverdue => isPending && age.inDays > 7;

  // Get refund percentage if refunded
  double? get refundPercentage {
    if (refundAmount == null || refundAmount == 0 || amount == 0) return null;
    return ((refundAmount! / amount) * 100);
  }
}

// Extension for PaymentTransaction list operations
extension PaymentTransactionListExtension on List<PaymentTransaction> {
  List<PaymentTransaction> get successfulTransactions =>
      where((tx) => tx.isSuccessful).toList();

  List<PaymentTransaction> get pendingTransactions =>
      where((tx) => tx.isPending).toList();

  List<PaymentTransaction> get failedTransactions =>
      where((tx) => tx.isFailed).toList();

  List<PaymentTransaction> get processingTransactions =>
      where((tx) => tx.isProcessing).toList();

  List<PaymentTransaction> get refundedTransactions =>
      where((tx) => tx.isRefundedStatus).toList();

  List<PaymentTransaction> get recentTransactions =>
      where((tx) => tx.isRecent).toList();

  List<PaymentTransaction> get overdueTransactions =>
      where((tx) => tx.isOverdue).toList();

  List<PaymentTransaction> getCorporateTransactions({bool corporate = true}) =>
      where((tx) => tx.isCorporate == corporate).toList();

  double get totalAmount => fold(0.0, (sum, tx) => sum + tx.amount);

  double get successfulAmount =>
      successfulTransactions.fold(0.0, (sum, tx) => sum + tx.amount);

  double get refundedAmount =>
      refundedTransactions.fold(0.0, (sum, tx) => sum + (tx.refundAmount ?? 0));

  Map<PaymentMethod, List<PaymentTransaction>> groupByPaymentMethod() {
    final grouped = <PaymentMethod, List<PaymentTransaction>>{};
    for (final tx in this) {
      grouped.putIfAbsent(tx.paymentMethod, () => []).add(tx);
    }
    return grouped;
  }

  Map<PaymentStatus, List<PaymentTransaction>> groupByStatus() {
    final grouped = <PaymentStatus, List<PaymentTransaction>>{};
    for (final tx in this) {
      grouped.putIfAbsent(tx.status, () => []).add(tx);
    }
    return grouped;
  }

  Map<String, List<PaymentTransaction>> groupByCurrency() {
    final grouped = <String, List<PaymentTransaction>>{};
    for (final tx in this) {
      grouped.putIfAbsent(tx.currency, () => []).add(tx);
    }
    return grouped;
  }

  List<PaymentTransaction> getTransactionsByMethod(PaymentMethod method) =>
      where((tx) => tx.paymentMethod == method).toList();

  List<PaymentTransaction> getTransactionsByStatus(PaymentStatus status) =>
      where((tx) => tx.status == status).toList();

  List<PaymentTransaction> getTransactionsByCurrency(String currency) =>
      where((tx) => tx.currency == currency).toList();

  List<PaymentTransaction> getTransactionsByDateRange(
          DateTime start, DateTime end) =>
      where((tx) => tx.createdAt.isAfter(start) && tx.createdAt.isBefore(end))
          .toList();

  List<PaymentTransaction> getTransactionsForUser(String userId) =>
      where((tx) => tx.userId == userId).toList();

  // Get transactions for a specific order
  List<PaymentTransaction> getTransactionsForOrder(String orderId) =>
      where((tx) => tx.orderId == orderId).toList();
}

// Simplified transaction for quick display
class TransactionSummary {
  final String id;
  final double amount;
  final String currency;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final DateTime createdAt;
  final String? reference;

  TransactionSummary({
    required this.id,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.reference,
  });

  factory TransactionSummary.fromPaymentTransaction(PaymentTransaction tx) {
    return TransactionSummary(
      id: tx.id,
      amount: tx.amount,
      currency: tx.currency,
      paymentMethod: tx.paymentMethod,
      status: tx.status,
      createdAt: tx.createdAt,
      reference: tx.reference,
    );
  }

  String get formattedAmount {
    return CurrencyService.instance.formatPrice(amount, currencyCode: currency);
  }

  String get statusDisplay => status.displayName;
  Color get statusColor => status.color;
  IconData get paymentMethodIcon => paymentMethod.icon;
}
