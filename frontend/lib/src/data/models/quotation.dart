// lib/src/data/models/quotation.dart

/// Quotation data model for the frontend
class Quotation {
  final int id;
  final String quotationNumber;
  final String clientName;
  final String clientEmail;
  final String? clientPhone;
  final String? clientCompany;
  final String clientCountry;
  final String trainingType; // 'course', 'masterclass', 'learnership'
  final int? courseId;
  final String? courseName;
  final int? masterclassId;
  final String? masterclassName;
  final int? learnershipId;
  final String? learnershipName;
  final String trainingItemName; // Computed field
  final double basePrice;
  final String localCurrency;
  final double localAmount;
  final double exchangeRate;
  final int quantity;
  final double discountPercentage;
  final double discountAmount;
  final double subtotal;
  final double vatAmount;
  final double totalAmount;
  final String? description;
  final int validityDays;
  final DateTime? expiresAt;
  final String status; // 'draft', 'sent', 'accepted', 'paid', 'expired', 'cancelled'
  final String? smatpayLink;
  final bool emailSent;
  final DateTime? emailSentAt;
  final bool smsSent;
  final DateTime? smsSentAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? daysUntilExpiry;

  const Quotation({
    required this.id,
    required this.quotationNumber,
    required this.clientName,
    required this.clientEmail,
    this.clientPhone,
    this.clientCompany,
    required this.clientCountry,
    required this.trainingType,
    this.courseId,
    this.courseName,
    this.masterclassId,
    this.masterclassName,
    this.learnershipId,
    this.learnershipName,
    required this.trainingItemName,
    required this.basePrice,
    required this.localCurrency,
    required this.localAmount,
    required this.exchangeRate,
    required this.quantity,
    required this.discountPercentage,
    required this.discountAmount,
    required this.subtotal,
    required this.vatAmount,
    required this.totalAmount,
    this.description,
    required this.validityDays,
    this.expiresAt,
    required this.status,
    this.smatpayLink,
    required this.emailSent,
    this.emailSentAt,
    required this.smsSent,
    this.smsSentAt,
    required this.createdAt,
    required this.updatedAt,
    this.daysUntilExpiry,
  });

  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      id: json['id'] ?? 0,
      quotationNumber: json['quotation_number'] ?? '',
      clientName: json['client_name'] ?? '',
      clientEmail: json['client_email'] ?? '',
      clientPhone: json['client_phone'],
      clientCompany: json['client_company'],
      clientCountry: json['client_country'] ?? '',
      trainingType: json['training_type'] ?? '',
      courseId: json['course_id'],
      courseName: json['course_name'],
      masterclassId: json['masterclass_id'],
      masterclassName: json['masterclass_name'],
      learnershipId: json['learnership_id'],
      learnershipName: json['learnership_name'],
      trainingItemName: json['training_item'] ?? json['training_item_name'] ?? '',
      basePrice: double.tryParse(json['base_price']?.toString() ?? '0') ?? 0.0,
      localCurrency: json['local_currency'] ?? 'USD',
      localAmount: double.tryParse(json['local_amount']?.toString() ?? '0') ?? 0.0,
      exchangeRate: double.tryParse(json['exchange_rate']?.toString() ?? '1') ?? 1.0,
      quantity: json['quantity'] ?? 1,
      discountPercentage: double.tryParse(json['discount_percentage']?.toString() ?? '0') ?? 0.0,
      discountAmount: double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0.0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      vatAmount: double.tryParse(json['vat_amount']?.toString() ?? '0') ?? 0.0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      description: json['description'],
      validityDays: json['validity_days'] ?? 30,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      status: json['status'] ?? 'draft',
      smatpayLink: json['smatpay_link'] ?? json['smatpay_payment_link'],
      emailSent: json['email_sent'] ?? false,
      emailSentAt: json['email_sent_at'] != null ? DateTime.parse(json['email_sent_at']) : null,
      smsSent: json['sms_sent'] ?? false,
      smsSentAt: json['sms_sent_at'] != null ? DateTime.parse(json['sms_sent_at']) : null,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      daysUntilExpiry: json['days_until_expiry'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quotation_number': quotationNumber,
      'client_name': clientName,
      'client_email': clientEmail,
      'client_phone': clientPhone,
      'client_company': clientCompany,
      'client_country': clientCountry,
      'training_type': trainingType,
      'course_id': courseId,
      'course_name': courseName,
      'masterclass_id': masterclassId,
      'masterclass_name': masterclassName,
      'learnership_id': learnershipId,
      'learnership_name': learnershipName,
      'training_item_name': trainingItemName,
      'base_price': basePrice.toString(),
      'local_currency': localCurrency,
      'local_amount': localAmount.toString(),
      'exchange_rate': exchangeRate.toString(),
      'quantity': quantity,
      'discount_percentage': discountPercentage.toString(),
      'discount_amount': discountAmount.toString(),
      'subtotal': subtotal.toString(),
      'vat_amount': vatAmount.toString(),
      'total_amount': totalAmount.toString(),
      'description': description,
      'validity_days': validityDays,
      'expires_at': expiresAt?.toIso8601String(),
      'status': status,
      'smatpay_payment_link': smatpayLink,
      'email_sent': emailSent,
      'email_sent_at': emailSentAt?.toIso8601String(),
      'sms_sent': smsSent,
      'sms_sent_at': smsSentAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'days_until_expiry': daysUntilExpiry,
    };
  }

  // Helper methods
  bool get isExpired => expiresAt?.isBefore(DateTime.now()) ?? false;
  bool get isDraft => status == 'draft';
  bool get isSent => status == 'sent';
  bool get isAccepted => status == 'accepted';
  bool get isPaid => status == 'paid';
  bool get isCancelled => status == 'cancelled';

  String get statusDisplay {
    switch (status) {
      case 'draft': return 'Draft';
      case 'sent': return 'Sent';
      case 'accepted': return 'Accepted';
      case 'paid': return 'Paid';
      case 'expired': return 'Expired';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  String get trainingTypeDisplay {
    switch (trainingType) {
      case 'course': return 'AI Certs Course';
      case 'masterclass': return 'Masterclass';
      case 'learnership': return 'Learnership';
      default: return trainingType;
    }
  }
}

/// Training item for quotation creation
class TrainingItem {
  final int id;
  final String name;
  final String code;
  final String? description;
  final String? category;
  final String? programCode;
  final String? sector;
  final int? durationHours;
  final int? durationMonths;
  final int? nqfLevel;
  final int? maxParticipants;
  final int? maxLearners;
  final double priceUsd;
  final double localPrice;
  final String currency;
  final DateTime? startDate;
  final DateTime? endDate;

  const TrainingItem({
    required this.id,
    required this.name,
    this.code = '',
    this.description,
    this.category,
    this.programCode,
    this.sector,
    this.durationHours,
    this.durationMonths,
    this.nqfLevel,
    this.maxParticipants,
    this.maxLearners,
    required this.priceUsd,
    required this.localPrice,
    required this.currency,
    this.startDate,
    this.endDate,
  });

  factory TrainingItem.fromJson(Map<String, dynamic> json, String type) {
    return TrainingItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['title'] ?? '',
      code: json['code'] ?? json['program_code'] ?? '',
      description: json['description'],
      category: json['category'],
      programCode: json['program_code'],
      sector: json['sector'],
      durationHours: json['duration_hours'],
      durationMonths: json['duration_months'],
      nqfLevel: json['nqf_level'],
      maxParticipants: json['max_participants'],
      maxLearners: json['max_learners'],
      priceUsd: double.tryParse(json['price_usd']?.toString() ?? '0') ?? 0.0,
      localPrice: double.tryParse(json['local_price']?.toString() ?? '0') ?? 0.0,
      currency: json['currency'] ?? 'USD',
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
    );
  }
}

/// Quotation creation request
class CreateQuotationRequest {
  final String clientName;
  final String clientEmail;
  final String? clientPhone;
  final String? clientCompany;
  final String clientCountry;
  final String trainingType;
  final int itemId;
  final int quantity;
  final double? discountPercentage;
  final String? description;
  final int? validityDays;

  const CreateQuotationRequest({
    required this.clientName,
    required this.clientEmail,
    this.clientPhone,
    this.clientCompany,
    required this.clientCountry,
    required this.trainingType,
    required this.itemId,
    this.quantity = 1,
    this.discountPercentage,
    this.description,
    this.validityDays,
  });

  Map<String, dynamic> toJson() {
    return {
      'client_name': clientName,
      'client_email': clientEmail,
      'client_phone': clientPhone,
      'client_company': clientCompany,
      'client_country': clientCountry,
      'training_type': trainingType,
      'item_id': itemId,
      'quantity': quantity,
      'discount_percentage': discountPercentage,
      'description': description,
      'validity_days': validityDays,
    };
  }
}