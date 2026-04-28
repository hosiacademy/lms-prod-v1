class CouponValidation {
  final bool valid;
  final String message;
  final int? couponId;
  final String? code;
  final String? name;
  final String? description;
  final String? discountType;
  final double? discountValue;
  final double? maxDiscountAmount;
  final double? discountAmount;
  final double? originalAmount;
  final double? finalAmount;
  final int? daysRemaining;

  const CouponValidation({
    required this.valid,
    required this.message,
    this.couponId,
    this.code,
    this.name,
    this.description,
    this.discountType,
    this.discountValue,
    this.maxDiscountAmount,
    this.discountAmount,
    this.originalAmount,
    this.finalAmount,
    this.daysRemaining,
  });

  factory CouponValidation.fromJson(Map<String, dynamic> json) {
    return CouponValidation(
      valid: json['valid'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      couponId: json['coupon_id'] as int?,
      code: json['code'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      discountType: json['discount_type'] as String?,
      discountValue: (json['discount_value'] as num?)?.toDouble(),
      maxDiscountAmount: (json['max_discount_amount'] as num?)?.toDouble(),
      discountAmount: (json['discount_amount'] as num?)?.toDouble(),
      originalAmount: (json['original_amount'] as num?)?.toDouble(),
      finalAmount: (json['final_amount'] as num?)?.toDouble(),
      daysRemaining: json['days_remaining'] as int?,
    );
  }

  factory CouponValidation.invalid(String message) =>
      CouponValidation(valid: false, message: message);

  String get summaryLabel {
    if (!valid || discountType == null) return '';
    switch (discountType) {
      case 'percentage':
        return '${discountValue?.toStringAsFixed(0)}% OFF';
      case 'fixed':
        return '\$${discountValue?.toStringAsFixed(0)} OFF';
      case 'capped_percentage':
        return '${discountValue?.toStringAsFixed(0)}% OFF (max \$$maxDiscountAmount)';
      default:
        return '';
    }
  }
}
