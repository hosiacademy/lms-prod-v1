// payment_enums.dart - INTEGRATED VERSION
import 'package:flutter/material.dart';

enum PaymentMethod {
  creditCard,
  mobileMoney,
  bankTransfer,
  payPal,
  mpesa,
  paystack,
  stripe,
  flutterwave,
  airtelMoney,
  mtnMobileMoney,
  orangeMoney,
  vodacomMpesa,
  tigoPesa,
  chipperCash,
  fawry,
  remita,
  pesapal,
  snapscan,
  payfast,
  paymob,
  wallet,
  cash,
  voucher,
  installments,
  other;

  // Get the string value for API/DB
  String get value {
    switch (this) {
      case PaymentMethod.creditCard:
        return 'credit_card';
      case PaymentMethod.mobileMoney:
        return 'mobile_money';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.payPal:
        return 'paypal';
      case PaymentMethod.mpesa:
        return 'mpesa';
      case PaymentMethod.paystack:
        return 'paystack';
      case PaymentMethod.stripe:
        return 'stripe';
      case PaymentMethod.flutterwave:
        return 'flutterwave';
      case PaymentMethod.airtelMoney:
        return 'airtel_money';
      case PaymentMethod.mtnMobileMoney:
        return 'mtn_mobile_money';
      case PaymentMethod.orangeMoney:
        return 'orange_money';
      case PaymentMethod.vodacomMpesa:
        return 'vodacom_mpesa';
      case PaymentMethod.tigoPesa:
        return 'tigo_pesa';
      case PaymentMethod.chipperCash:
        return 'chipper_cash';
      case PaymentMethod.fawry:
        return 'fawry';
      case PaymentMethod.remita:
        return 'remita';
      case PaymentMethod.pesapal:
        return 'pesapal';
      case PaymentMethod.snapscan:
        return 'snapscan';
      case PaymentMethod.payfast:
        return 'payfast';
      case PaymentMethod.paymob:
        return 'paymob';
      case PaymentMethod.wallet:
        return 'wallet';
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.voucher:
        return 'voucher';
      case PaymentMethod.installments:
        return 'installments';
      case PaymentMethod.other:
        return 'other';
    }
  }

  // Get display name for UI
  String get displayName {
    switch (this) {
      case PaymentMethod.creditCard:
        return 'Credit/Debit Card';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.payPal:
        return 'PayPal';
      case PaymentMethod.mpesa:
        return 'M-Pesa';
      case PaymentMethod.paystack:
        return 'Paystack';
      case PaymentMethod.stripe:
        return 'Stripe';
      case PaymentMethod.flutterwave:
        return 'Flutterwave';
      case PaymentMethod.airtelMoney:
        return 'Airtel Money';
      case PaymentMethod.mtnMobileMoney:
        return 'MTN Mobile Money';
      case PaymentMethod.orangeMoney:
        return 'Orange Money';
      case PaymentMethod.vodacomMpesa:
        return 'Vodacom M-Pesa';
      case PaymentMethod.tigoPesa:
        return 'Tigo Pesa';
      case PaymentMethod.chipperCash:
        return 'Chipper Cash';
      case PaymentMethod.fawry:
        return 'Fawry';
      case PaymentMethod.remita:
        return 'Remita';
      case PaymentMethod.pesapal:
        return 'Pesapal';
      case PaymentMethod.snapscan:
        return 'SnapScan';
      case PaymentMethod.payfast:
        return 'PayFast';
      case PaymentMethod.paymob:
        return 'Paymob';
      case PaymentMethod.wallet:
        return 'Digital Wallet';
      case PaymentMethod.cash:
        return 'Cash Payment';
      case PaymentMethod.voucher:
        return 'Voucher/Coupon';
      case PaymentMethod.installments:
        return 'Installments';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  // Get icon for UI
  IconData get icon {
    switch (this) {
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.mobileMoney:
      case PaymentMethod.mpesa:
      case PaymentMethod.mtnMobileMoney:
      case PaymentMethod.airtelMoney:
      case PaymentMethod.orangeMoney:
      case PaymentMethod.vodacomMpesa:
      case PaymentMethod.tigoPesa:
        return Icons.phone_android;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.payPal:
      case PaymentMethod.paystack:
      case PaymentMethod.stripe:
      case PaymentMethod.flutterwave:
      case PaymentMethod.fawry:
      case PaymentMethod.remita:
      case PaymentMethod.pesapal:
      case PaymentMethod.snapscan:
      case PaymentMethod.payfast:
      case PaymentMethod.paymob:
        return Icons.payment;
      case PaymentMethod.chipperCash:
        return Icons.swap_horiz;
      case PaymentMethod.wallet:
        return Icons.wallet;
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.voucher:
        return Icons.card_giftcard;
      case PaymentMethod.installments:
        return Icons.schedule;
      case PaymentMethod.other:
        return Icons.more_horiz;
    }
  }

  // Convert from string value back to enum
  static PaymentMethod fromValue(String value) {
    switch (value) {
      case 'credit_card':
        return PaymentMethod.creditCard;
      case 'mobile_money':
        return PaymentMethod.mobileMoney;
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      case 'paypal':
        return PaymentMethod.payPal;
      case 'mpesa':
        return PaymentMethod.mpesa;
      case 'paystack':
        return PaymentMethod.paystack;
      case 'stripe':
        return PaymentMethod.stripe;
      case 'flutterwave':
        return PaymentMethod.flutterwave;
      case 'airtel_money':
        return PaymentMethod.airtelMoney;
      case 'mtn_mobile_money':
        return PaymentMethod.mtnMobileMoney;
      case 'orange_money':
        return PaymentMethod.orangeMoney;
      case 'vodacom_mpesa':
        return PaymentMethod.vodacomMpesa;
      case 'tigo_pesa':
        return PaymentMethod.tigoPesa;
      case 'chipper_cash':
        return PaymentMethod.chipperCash;
      case 'fawry':
        return PaymentMethod.fawry;
      case 'remita':
        return PaymentMethod.remita;
      case 'pesapal':
        return PaymentMethod.pesapal;
      case 'snapscan':
        return PaymentMethod.snapscan;
      case 'payfast':
        return PaymentMethod.payfast;
      case 'paymob':
        return PaymentMethod.paymob;
      case 'wallet':
        return PaymentMethod.wallet;
      case 'cash':
        return PaymentMethod.cash;
      case 'voucher':
        return PaymentMethod.voucher;
      case 'installments':
        return PaymentMethod.installments;
      default:
        return PaymentMethod.other;
    }
  }
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
  partiallyRefunded,
  disputed,
  onHold,
  expired;

  // Get the string value for API/DB
  String get value {
    switch (this) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.processing:
        return 'processing';
      case PaymentStatus.completed:
        return 'completed';
      case PaymentStatus.failed:
        return 'failed';
      case PaymentStatus.cancelled:
        return 'cancelled';
      case PaymentStatus.refunded:
        return 'refunded';
      case PaymentStatus.partiallyRefunded:
        return 'partially_refunded';
      case PaymentStatus.disputed:
        return 'disputed';
      case PaymentStatus.onHold:
        return 'on_hold';
      case PaymentStatus.expired:
        return 'expired';
    }
  }

  // Get display name for UI
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.partiallyRefunded:
        return 'Partially Refunded';
      case PaymentStatus.disputed:
        return 'Disputed';
      case PaymentStatus.onHold:
        return 'On Hold';
      case PaymentStatus.expired:
        return 'Expired';
    }
  }

  // Get color for status badge
  Color get color {
    switch (this) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.processing:
        return Colors.blue;
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
      case PaymentStatus.refunded:
        return Colors.purple;
      case PaymentStatus.partiallyRefunded:
        return Colors.purpleAccent;
      case PaymentStatus.disputed:
        return Colors.amber;
      case PaymentStatus.onHold:
        return Colors.orangeAccent;
      case PaymentStatus.expired:
        return Colors.grey.shade700;
    }
  }

  // Convert from string value back to enum
  static PaymentStatus fromValue(String value) {
    switch (value) {
      case 'pending':
        return PaymentStatus.pending;
      case 'processing':
        return PaymentStatus.processing;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'partially_refunded':
        return PaymentStatus.partiallyRefunded;
      case 'disputed':
        return PaymentStatus.disputed;
      case 'on_hold':
        return PaymentStatus.onHold;
      case 'expired':
        return PaymentStatus.expired;
      default:
        return PaymentStatus.pending;
    }
  }
}

class PaymentConstants {
  static const Map<String, String> currencySymbols = {
    'KES': 'KSh',
    'NGN': '₦',
    'GHS': 'GH₵',
    'ZAR': 'R',
    'TZS': 'TSh',
    'UGX': 'USh',
    'RWF': 'RF',
    'ETB': 'Br',
    'ZMW': 'ZK',
    'ZWL': '\$',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
  };

  static String getCurrencySymbol(String currencyCode) {
    return currencySymbols[currencyCode] ?? '\$';
  }

  // Common payment methods by country
  static Map<String, List<PaymentMethod>> countryPaymentMethods = {
    // East Africa
    'KE': [
      PaymentMethod.mpesa,
      PaymentMethod.creditCard,
      PaymentMethod.bankTransfer,
      PaymentMethod.flutterwave
    ], // Kenya
    'TZ': [
      PaymentMethod.mpesa,
      PaymentMethod.airtelMoney,
      PaymentMethod.tigoPesa,
      PaymentMethod.creditCard
    ], // Tanzania
    'UG': [
      PaymentMethod.mtnMobileMoney,
      PaymentMethod.airtelMoney,
      PaymentMethod.creditCard,
      PaymentMethod.flutterwave
    ], // Uganda
    'RW': [
      PaymentMethod.mtnMobileMoney,
      PaymentMethod.airtelMoney,
      PaymentMethod.creditCard
    ], // Rwanda
    'ET': [PaymentMethod.creditCard, PaymentMethod.bankTransfer], // Ethiopia

    // West Africa
    'NG': [
      PaymentMethod.paystack,
      PaymentMethod.flutterwave,
      PaymentMethod.creditCard,
      PaymentMethod.bankTransfer
    ], // Nigeria
    'GH': [
      PaymentMethod.mtnMobileMoney,
      PaymentMethod.creditCard,
      PaymentMethod.flutterwave
    ], // Ghana
    'CI': [
      PaymentMethod.orangeMoney,
      PaymentMethod.mtnMobileMoney,
      PaymentMethod.creditCard
    ], // Ivory Coast
    'SN': [PaymentMethod.orangeMoney, PaymentMethod.creditCard], // Senegal

    // Southern Africa
    'ZA': [
      PaymentMethod.snapscan,
      PaymentMethod.payfast,
      PaymentMethod.creditCard,
      PaymentMethod.bankTransfer
    ], // South Africa
    'ZM': [
      PaymentMethod.mtnMobileMoney,
      PaymentMethod.airtelMoney,
      PaymentMethod.creditCard
    ], // Zambia

    'BW': [PaymentMethod.creditCard, PaymentMethod.bankTransfer], // Botswana

    // North Africa
    'EG': [
      PaymentMethod.fawry,
      PaymentMethod.paymob,
      PaymentMethod.creditCard
    ], // Egypt
    'MA': [PaymentMethod.creditCard, PaymentMethod.bankTransfer], // Morocco

    // Global
    'US': [
      PaymentMethod.creditCard,
      PaymentMethod.payPal,
      PaymentMethod.stripe
    ], // USA
    'EU': [
      PaymentMethod.creditCard,
      PaymentMethod.payPal,
      PaymentMethod.bankTransfer
    ], // Europe
  };

  // Get available payment methods for a country
  static List<PaymentMethod> getPaymentMethodsForCountry(String countryCode) {
    return countryPaymentMethods[countryCode] ??
        [
          PaymentMethod.creditCard,
          PaymentMethod.mobileMoney,
          PaymentMethod.bankTransfer
        ];
  }

  // Check if payment method is available in country
  static bool isPaymentMethodAvailable(
      String countryCode, PaymentMethod method) {
    final methods = countryPaymentMethods[countryCode];
    if (methods == null) {
      // If country not in map, allow common methods
      return [
        PaymentMethod.creditCard,
        PaymentMethod.mobileMoney,
        PaymentMethod.bankTransfer,
        PaymentMethod.payPal,
        PaymentMethod.flutterwave,
      ].contains(method);
    }
    return methods.contains(method);
  }
}

// Helper extension for PaymentMethod
extension PaymentMethodExtension on PaymentMethod {
  bool get isMobileMoney {
    return [
      PaymentMethod.mobileMoney,
      PaymentMethod.mpesa,
      PaymentMethod.mtnMobileMoney,
      PaymentMethod.airtelMoney,
      PaymentMethod.orangeMoney,
      PaymentMethod.vodacomMpesa,
      PaymentMethod.tigoPesa,
    ].contains(this);
  }

  bool get isCard {
    return this == PaymentMethod.creditCard;
  }

  bool get isBankTransfer {
    return this == PaymentMethod.bankTransfer;
  }

  bool get isDigitalWallet {
    return [
      PaymentMethod.payPal,
      PaymentMethod.flutterwave,
      PaymentMethod.paystack,
      PaymentMethod.stripe,
    ].contains(this);
  }
}

// Helper extension for PaymentStatus
extension PaymentStatusExtension on PaymentStatus {
  bool get isSuccessful {
    return this == PaymentStatus.completed;
  }

  bool get isFailed {
    return [
      PaymentStatus.failed,
      PaymentStatus.cancelled,
      PaymentStatus.expired
    ].contains(this);
  }

  bool get isPending {
    return [
      PaymentStatus.pending,
      PaymentStatus.processing,
      PaymentStatus.onHold
    ].contains(this);
  }
}
