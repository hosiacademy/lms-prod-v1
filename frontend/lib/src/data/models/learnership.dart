// lib/src/data/models/learnership.dart

import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'course.dart';
import '../../core/constants/pricing_constants.dart';
import '../../core/services/currency_service.dart';

@immutable
class CertificationItem {
  final int id;
  final String name;
  final String description;
  final String phase;
  final double certCost;
  final String? formattedCertCost;
  final int order;

  CertificationItem({
    required this.id,
    required this.name,
    required this.description,
    required this.phase,
    required this.certCost,
    this.formattedCertCost,
    required this.order,
  });

  factory CertificationItem.fromJson(Map<String, dynamic> json) {
    return CertificationItem(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
      phase: json['phase'] as String? ?? '',
      certCost: _parseDecimal(json['cert_cost']),
      formattedCertCost: json['formatted_cert_cost'] as String?,
      order: json['order'] as int? ?? 1,
    );
  }

  static double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }

  String get phaseDisplay {
    switch (phase) {
      case 'phase_1_foundation':
        return 'Phase 1 – Foundation';
      case 'phase_2_vendor_spec':
        return 'Phase 2 – Vendor Spec';
      case 'phase_3_practical':
        return 'Phase 3 – Practical/Readiness';
      default:
        return phase;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'phase': phase,
      'cert_cost': certCost,
      'order': order,
    };
  }
}

@immutable
class CertificationTrack {
  final int id;
  final String name;
  final String trackType;
  final String description;
  final double totalCertCost;
  final double platformCost;
  final double instructorCost;
  final double totalCost;
  final double salesPrice;
  final double monthlyPrice;
  final double grossMargin;
  final List<CertificationItem> certifications;
  
  // Localized pricing
  final String? formattedTotalCertCost;
  final String? formattedPlatformCost;
  final String? formattedInstructorCost;
  final String? formattedTotalCost;
  final String? formattedSalesPrice;
  final String? formattedMonthlyPrice;
  final String? formattedGrossMargin;

  CertificationTrack({
    required this.id,
    required this.name,
    required this.trackType,
    required this.description,
    required this.totalCertCost,
    required this.platformCost,
    required this.instructorCost,
    required this.totalCost,
    required this.salesPrice,
    required this.monthlyPrice,
    required this.grossMargin,
    required this.certifications,
    this.formattedTotalCertCost,
    this.formattedPlatformCost,
    this.formattedInstructorCost,
    this.formattedTotalCost,
    this.formattedSalesPrice,
    this.formattedMonthlyPrice,
    this.formattedGrossMargin,
  });

  factory CertificationTrack.fromJson(Map<String, dynamic> json) {
    final certsJson = json['certifications'] as List<dynamic>? ?? [];
    return CertificationTrack(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown Track',
      trackType: json['track_type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      totalCertCost: _parseDecimal(json['total_cert_cost_localized'] ?? json['total_cert_cost']),
      platformCost: _parseDecimal(json['platform_cost_localized'] ?? json['platform_cost']),
      instructorCost: _parseDecimal(json['instructor_cost_localized'] ?? json['instructor_cost']),
      totalCost: _parseDecimal(json['total_cost_localized'] ?? json['total_cost']),
      salesPrice: _parseDecimal(json['sales_price_localized'] ?? json['sales_price']),
      monthlyPrice: _parseDecimal(json['monthly_price_localized'] ?? json['monthly_price']),
      grossMargin: _parseDecimal(json['gross_margin_localized'] ?? json['gross_margin']),
      certifications: certsJson.map((c) => CertificationItem.fromJson(c as Map<String, dynamic>)).toList(),
      formattedTotalCertCost: json['formatted_total_cert_cost'] as String?,
      formattedPlatformCost: json['formatted_platform_cost'] as String?,
      formattedInstructorCost: json['formatted_instructor_cost'] as String?,
      formattedTotalCost: json['formatted_total_cost'] as String?,
      formattedSalesPrice: json['formatted_sales_price'] as String?,
      formattedMonthlyPrice: json['formatted_monthly_price'] as String?,
      formattedGrossMargin: json['formatted_gross_margin'] as String?,
    );
  }

  static double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }

  List<CertificationItem> getPhaseItems(String phase) {
    return certifications.where((c) => c.phase == phase).toList();
  }

  double getPhaseTotal(String phase) {
    return getPhaseItems(phase).fold(0.0, (sum, item) => sum + item.certCost);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'track_type': trackType,
      'description': description,
      'total_cert_cost': totalCertCost,
      'platform_cost': platformCost,
      'instructor_cost': instructorCost,
      'total_cost': totalCost,
      'sales_price': salesPrice,
      'monthly_price': monthlyPrice,
      'gross_margin': grossMargin,
      'certifications': certifications.map((c) => c.toJson()).toList(),
    };
  }
}

@immutable
class Learnership {
  final int id;
  final String title;
  final String slug;
  final String
      specialization; // e.g., "Data Science & AI", "Blockchain Development"
  final String?
      nqfLevel; // National Qualifications Framework level (e.g., "NQF 5", "NQF 6")
  final int? durationMonths;
  final String? description;
  final String? focus; // Brief focus area description
  final String? entryRequirements;
  final String? careerOutcomes;
  final String? targetAudience;
  final String? category; // e.g., "Technology", "Business", "Healthcare"
  final String? role; // e.g., "ai_developer_ml_engineer"
  final int? durationWeeks;
  final String? intakeFrequency;
  final List<String>? prerequisites;

  // Status and enrollment
  final String? status; // "open", "in_progress", "closed", "upcoming"
  final int? maxParticipants;
  final int? currentParticipants;
  final DateTime? enrollmentDeadline;
  final DateTime? startDate;
  final DateTime? endDate;

  // Provider information
  final String? provider; // Institution or company providing the learnership
  final String? accreditationBody; // e.g., "SAQA", "QCTO"
  final String? certificate; // Qualification name upon completion

  // Location
  final String? deliveryMode; // "online", "in_person", "hybrid"
  final String? location;
  final String? country;
  final String? city;

  // Financial
  final double? stipendAmount; // Monthly stipend if applicable
  final double?
      price; // Enrollment fee if applicable (most learnerships are free)
  final String? currency;
  final bool? isFunded; // Whether it's employer-funded or government-funded

  // Additional fields
  final bool isFeatured;
  final bool active;
  final bool isOffered;
  final String? imageUrl;
  final List<String>? skills; // Skills to be gained
  final List<String>? modules; // Learning modules

  // Related objects
  final int? providerId;
  final Map<String, dynamic>? providerDetail;
  final CertificationTrack? certificationTrack;

  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Learnership({
    required this.id,
    required this.title,
    required this.slug,
    required this.specialization,
    this.nqfLevel,
    this.durationMonths,
    this.description,
    this.focus,
    this.entryRequirements,
    this.careerOutcomes,
    this.targetAudience,
    this.category,
    this.status,
    this.maxParticipants,
    this.currentParticipants,
    this.enrollmentDeadline,
    this.startDate,
    this.endDate,
    this.provider,
    this.accreditationBody,
    this.certificate,
    this.deliveryMode,
    this.location,
    this.country,
    this.city,
    this.stipendAmount,
    this.price,
    this.currency,
    this.isFunded = false,
    this.isFeatured = false,
    this.active = true,
    this.isOffered = true,
    this.imageUrl,
    this.skills,
    this.modules,
    this.providerId,
    this.providerDetail,
    this.certificationTrack,
    this.role,
    this.durationWeeks,
    this.intakeFrequency,
    this.prerequisites,
    this.createdAt,
    this.updatedAt,
  });

  factory Learnership.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? dateString) {
      if (dateString == null) return null;
      try {
        return DateTime.tryParse(dateString);
      } catch (e) {
        return null;
      }
    }

    List<String>? parseStringList(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is String) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (e) {
          // If parsing fails, split by comma
          return value.split(',').map((s) => s.trim()).toList();
        }
      }
      return null;
    }

    // Parse nested provider object
    int? providerId;
    Map<String, dynamic>? providerDetail;
    if (json['provider'] != null) {
      if (json['provider'] is int) {
        providerId = json['provider'] as int;
      } else if (json['provider'] is Map<String, dynamic>) {
        providerDetail = json['provider'] as Map<String, dynamic>;
        providerId = providerDetail['id'] as int?;
      } else if (json['provider'] is String) {
        // Provider is just a name string
      }
    } else if (json['provider_detail'] != null) {
      providerDetail = json['provider_detail'] as Map<String, dynamic>;
      providerId = providerDetail['id'] as int?;
    }

    return Learnership(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Untitled Learnership',
      slug: json['slug'] as String? ?? '',
      specialization: json['specialization'] as String? ?? '',
      nqfLevel: json['nqf_level'] as String?,
      durationMonths: json['duration_months'] as int?,
      description: json['description'] as String?,
      focus: json['focus'] as String?,
      entryRequirements: json['entry_requirements'] as String?,
      careerOutcomes: json['career_outcomes'] as String?,
      targetAudience: json['target_audience'] as String?,
      category: json['category'] as String?,
      status: json['status'] as String? ?? 'open',
      maxParticipants: json['max_participants'] as int?,
      currentParticipants: json['current_participants'] as int? ?? 0,
      enrollmentDeadline: parseDate(json['enrollment_deadline'] as String?),
      startDate: parseDate(json['start_date'] as String?),
      endDate: parseDate(json['end_date'] as String?),
      provider: json['provider'] is String
          ? json['provider'] as String
          : json['provider_name'] as String?,
      accreditationBody: json['accreditation_body'] as String?,
      certificate: json['certificate'] as String?,
      deliveryMode: json['delivery_mode'] as String? ?? 'hybrid',
      location: json['location'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
      stipendAmount: json['stipend_amount'] != null
          ? double.tryParse(json['stipend_amount'].toString())
          : null,
      price: json['price'] != null ||
              json['enrollment_fee'] != null ||
              json['cost_usd'] != null
          ? double.tryParse(
              (json['price'] ?? json['enrollment_fee'] ?? json['cost_usd'])
                  .toString())
          : null,
      currency: json['currency'] as String? ?? 'USD',
      isFunded: json['is_funded'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      active: json['active'] as bool? ?? true,
      isOffered: json['is_offered'] as bool? ?? true,
      imageUrl: json['image_url'] as String?,
      skills: parseStringList(json['skills']),
      modules: parseStringList(json['modules']),
      providerId: providerId,
      providerDetail: providerDetail,
      certificationTrack: json['certification_track'] != null
          ? CertificationTrack.fromJson(json['certification_track'] as Map<String, dynamic>)
          : null,
      role: json['role'] as String?,
      durationWeeks: json['duration_weeks'] as int?,
      intakeFrequency: json['intake_frequency'] as String?,
      prerequisites: parseStringList(json['prerequisites']),
      createdAt: parseDate(json['created_at'] as String?),
      updatedAt: parseDate(json['updated_at'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'specialization': specialization,
      'nqf_level': nqfLevel,
      'duration_months': durationMonths,
      'description': description,
      'focus': focus,
      'entry_requirements': entryRequirements,
      'career_outcomes': careerOutcomes,
      'target_audience': targetAudience,
      'category': category,
      'status': status,
      'max_participants': maxParticipants,
      'current_participants': currentParticipants,
      'enrollment_deadline': enrollmentDeadline?.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'provider': provider,
      'accreditation_body': accreditationBody,
      'certificate': certificate,
      'delivery_mode': deliveryMode,
      'location': location,
      'country': country,
      'city': city,
      'stipend_amount': stipendAmount,
      'price': price,
      'currency': currency,
      'is_funded': isFunded,
      'is_featured': isFeatured,
      'active': active,
      'is_offered': isOffered,
      'image_url': imageUrl,
      'skills': skills,
      'modules': modules,
      'provider_id': providerId,
      'certification_track': certificationTrack?.toJson(),
      'role': role,
      'duration_weeks': durationWeeks,
      'intake_frequency': intakeFrequency,
      'prerequisites': prerequisites,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ─── HELPER METHODS ──────────────────────────────────────────────

  /// Get calculated price - returns LOCALIZED numeric value
  double get calculatedPriceUsd {
    // Both certificationTrack.salesPrice and price are now localized from backend if available
    if (certificationTrack != null && certificationTrack!.salesPrice > 0) {
      return certificationTrack!.salesPrice;
    }
    if (price != null && price! > 0) {
      return price!;
    }
    
    return 0.0; // Strictly from backend - no fallback to constants
  }

  /// Get monthly price - Prioritize database value
  double get calculatedMonthlyPriceUsd {
    if (certificationTrack != null && certificationTrack!.monthlyPrice > 0) {
      return certificationTrack!.monthlyPrice;
    }
    return calculatedPriceUsd > 0 ? calculatedPriceUsd / 12.0 : 0.0;
  }

  /// HARDENED: Get formatted total price in local currency
  /// Never shows USD - uses pre-formatted backend string if available
  String get formattedPrice {
    if (certificationTrack?.formattedSalesPrice != null) {
      return certificationTrack!.formattedSalesPrice!;
    }
    if (calculatedPriceUsd <= 0) return 'Contact for pricing';
    // calculatedPriceUsd is already localized, so use formatPrice
    return CurrencyService.instance.formatPrice(calculatedPriceUsd);
  }

  /// HARDENED: Get formatted monthly price in local currency
  String get formattedMonthlyPrice {
    if (calculatedMonthlyPriceUsd <= 0) return 'Contact for pricing';
    try {
      // calculatedMonthlyPriceUsd is derived from localized price, so use formatPrice
      return CurrencyService.instance.formatPrice(calculatedMonthlyPriceUsd);
    } catch (e) {
      return 'Contact for pricing';
    }
  }

  /// Legacy alias - deprecated, use calculatedPriceUsd instead
  double? get priceUsd => price;

  String get formattedDuration {
    if (durationMonths == null && durationWeeks == null)
      return 'Duration not set';
    if (durationWeeks != null && durationWeeks! > 0) {
      return '$durationWeeks weeks${durationMonths != null ? ' ($durationMonths months)' : ''}';
    }
    if (durationMonths! < 12) {
      return '$durationMonths month${durationMonths! > 1 ? 's' : ''}';
    } else {
      final years = durationMonths! ~/ 12;
      final months = durationMonths! % 12;
      if (months == 0) {
        return '$years year${years > 1 ? 's' : ''}';
      }
      return '$years year${years > 1 ? 's' : ''}, $months month${months > 1 ? 's' : ''}';
    }
  }

  String get formattedStipend {
    if (stipendAmount == null) return 'No stipend';
    return '${CurrencyService.instance.formatPrice(stipendAmount!, currencyCode: currency ?? 'USD')}/month';
  }

  String _getCurrencySymbol() {
    switch (currency?.toUpperCase()) {
      case 'ZAR':
        return 'R';
      case 'KES':
        return 'KSh';
      case 'NGN':
        return '₦';
      case 'GHS':
        return 'GH₵';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '\$';
    }
  }

  String get displayName {
    if (role != null && role!.isNotEmpty) {
      // Format role name: ai_developer_ml_engineer -> AI Developer ML Engineer
      return role!
          .split('_')
          .map((word) => word.length <= 2
              ? word.toUpperCase()
              : word[0].toUpperCase() + word.substring(1))
          .join(' ');
    }
    if (specialization.isNotEmpty) return specialization;
    return title;
  }

  String get formattedDateRange {
    if (startDate == null || endDate == null) return 'Dates not set';

    final start = startDate!;
    final end = endDate!;

    if (start.year == end.year) {
      if (start.month == end.month) {
        return '${_formatMonthDay(start)} - ${end.day}, ${end.year}';
      }
      return '${_formatMonthDay(start)} - ${_formatMonthDay(end)}, ${end.year}';
    }
    return '${_formatMonthDayYear(start)} - ${_formatMonthDayYear(end)}';
  }

  String _formatMonthDay(DateTime date) {
    return '${_getMonthAbbr(date.month)} ${date.day}';
  }

  String _formatMonthDayYear(DateTime date) {
    return '${_getMonthAbbr(date.month)} ${date.day}, ${date.year}';
  }

  String _getMonthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  bool get isEnrollmentOpen {
    if (status == 'closed') return false;
    if (enrollmentDeadline == null) return status == 'open';
    return enrollmentDeadline!.isAfter(DateTime.now()) && status == 'open';
  }

  bool get isUpcoming {
    if (startDate == null) return false;
    return startDate!.isAfter(DateTime.now());
  }

  bool get isOngoing {
    if (startDate == null || endDate == null) return false;
    final now = DateTime.now();
    return (now.isAfter(startDate!) || now.isAtSameMomentAs(startDate!)) &&
        (now.isBefore(endDate!) || now.isAtSameMomentAs(endDate!));
  }

  bool get isCompleted {
    if (endDate == null) return false;
    return endDate!.isBefore(DateTime.now());
  }

  int get spotsRemaining {
    if (maxParticipants == null || currentParticipants == null) return 0;
    return (maxParticipants! - currentParticipants!).clamp(0, maxParticipants!);
  }

  bool get isFull {
    if (maxParticipants == null || currentParticipants == null) return false;
    return currentParticipants! >= maxParticipants!;
  }

  String get displayLocation {
    if (deliveryMode == 'online') return 'Online';

    if (city != null && country != null) {
      return '$city, $country';
    } else if (city != null) {
      return city!;
    } else if (location != null) {
      return location!;
    } else if (country != null) {
      return country!;
    }

    return 'Location not specified';
  }

  String get statusDisplay {
    switch (status?.toLowerCase()) {
      case 'open':
        return 'Open for Enrollment';
      case 'in_progress':
        return 'In Progress';
      case 'closed':
        return 'Enrollment Closed';
      case 'upcoming':
        return 'Coming Soon';
      case 'completed':
        return 'Completed';
      default:
        return 'Open';
    }
  }

  String get deliveryModeDisplay {
    switch (deliveryMode?.toLowerCase()) {
      case 'online':
        return 'Online';
      case 'in_person':
        return 'In-Person';
      case 'hybrid':
        return 'Hybrid (Online + In-Person)';
      default:
        return deliveryMode ?? 'Hybrid';
    }
  }

  // ─── COPY WITH METHOD ───────────────────────────────────────────

  Learnership copyWith({
    int? id,
    String? title,
    String? slug,
    String? specialization,
    String? nqfLevel,
    int? durationMonths,
    String? description,
    String? focus,
    String? entryRequirements,
    String? careerOutcomes,
    String? targetAudience,
    String? category,
    String? status,
    int? maxParticipants,
    int? currentParticipants,
    DateTime? enrollmentDeadline,
    DateTime? startDate,
    DateTime? endDate,
    String? provider,
    String? accreditationBody,
    String? certificate,
    String? deliveryMode,
    String? location,
    String? country,
    String? city,
    double? stipendAmount,
    double? price,
    String? currency,
    bool? isFunded,
    bool? isFeatured,
    bool? active,
    bool? isOffered,
    String? imageUrl,
    List<String>? skills,
    List<String>? modules,
    int? providerId,
    Map<String, dynamic>? providerDetail,
    CertificationTrack? certificationTrack,
    String? role,
    int? durationWeeks,
    String? intakeFrequency,
    List<String>? prerequisites,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Learnership(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      specialization: specialization ?? this.specialization,
      nqfLevel: nqfLevel ?? this.nqfLevel,
      durationMonths: durationMonths ?? this.durationMonths,
      description: description ?? this.description,
      focus: focus ?? this.focus,
      entryRequirements: entryRequirements ?? this.entryRequirements,
      careerOutcomes: careerOutcomes ?? this.careerOutcomes,
      targetAudience: targetAudience ?? this.targetAudience,
      category: category ?? this.category,
      status: status ?? this.status,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      enrollmentDeadline: enrollmentDeadline ?? this.enrollmentDeadline,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      provider: provider ?? this.provider,
      accreditationBody: accreditationBody ?? this.accreditationBody,
      certificate: certificate ?? this.certificate,
      deliveryMode: deliveryMode ?? this.deliveryMode,
      location: location ?? this.location,
      country: country ?? this.country,
      city: city ?? this.city,
      stipendAmount: stipendAmount ?? this.stipendAmount,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      isFunded: isFunded ?? this.isFunded,
      isFeatured: isFeatured ?? this.isFeatured,
      active: active ?? this.active,
      isOffered: isOffered ?? this.isOffered,
      imageUrl: imageUrl ?? this.imageUrl,
      skills: skills ?? this.skills,
      modules: modules ?? this.modules,
      providerId: providerId ?? this.providerId,
      providerDetail: providerDetail ?? this.providerDetail,
      certificationTrack: certificationTrack ?? this.certificationTrack,
      role: role ?? this.role,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      intakeFrequency: intakeFrequency ?? this.intakeFrequency,
      prerequisites: prerequisites ?? this.prerequisites,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Learnership &&
        other.id == id &&
        other.title == title &&
        other.slug == slug;
  }

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ slug.hashCode;

  @override
  String toString() {
    return 'Learnership(id: $id, title: "$title", specialization: $specialization, status: $status)';
  }

  Course toCourse() {
    return Course(
      id: id.toString(),
      title: title,
      description: description,
      featureImageUrl: imageUrl,
      price: price ?? 0,
      startDate: startDate,
      endDate: endDate,
      status: status,
      instructorName: provider,
      durationHours:
          durationMonths != null ? durationMonths! * 160 : null, // Approx hours
      roleType: 'Learnership',
      certificationLevel: nqfLevel,
      industry: specialization,
      city: city,
      country: country,
    );
  }
}

// ─── LIST RESPONSE ────────────────────────────────────────────────

class LearnershipListResponse {
  final List<Learnership> learnerships;
  final int count;
  final String? next;
  final String? previous;

  LearnershipListResponse({
    required this.learnerships,
    required this.count,
    this.next,
    this.previous,
  });

  factory LearnershipListResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> results = json['results'] ?? [];
    return LearnershipListResponse(
      learnerships: results
          .map((item) => Learnership.fromJson(item as Map<String, dynamic>))
          .toList(),
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
    );
  }
}
