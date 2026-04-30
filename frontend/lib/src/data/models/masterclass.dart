// lib/src/data/models/masterclass.dart

import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'course.dart';
import '../../core/constants/pricing_constants.dart';
import '../../core/services/currency_service.dart';

@immutable
class Masterclass {
  final int id;
  final String title;
  final String slug;
  final String masterclassType;
  final String streamType; // 'professional' or 'technical'
  final String? tier; // 'tier_1', 'tier_2', 'tier_3'
  final String? focusArea;
  final String? targetAudience;
  final String? description;
  final double? priceUsd;
  final double? localPrice; // Backend-converted price in user's currency
  final String? formattedPriceStr;
  final String? formattedPricePhysical;
  final String? formattedPriceOnline;
  final double? onlinePrice; // Online attendance price (localized from backend)
  final double? physicalPrice; // Physical attendance price (localized from backend)
  final double? pricePhysicalUsd; // Physical attendance price in USD
  final double? priceOnlineUsd; // Online attendance price in USD
  final bool isFeatured;
  final bool active;
  final String? launchPhase;
  final bool hasOnlineOption; // NEW: Whether online attendance is allowed

  // Location fields - COMPREHENSIVE
  final String? country;
  final String? countryCode; // NEW: ISO country code (e.g., 'KE', 'NG', 'ZA')
  final String? countryName; // NEW: Full country name
  final String? city;
  final String? venue;
  final String? venueAddress;
  final List<dynamic>? locations; // NEW: Legacy JSON locations field

  // Date fields
  final DateTime? startDate;
  final DateTime? endDate;

  // Additional fields from your database
  final String? category; // NEW: Category field
  final String? currency; // NEW: Currency field
  final String?
      status; // NEW: Status field (scheduled, ongoing, completed, cancelled)
  final int? maxParticipants; // NEW: Maximum participants
  final int? currentParticipants; // NEW: Current participants count
  final String? notes; // NEW: Additional notes

  // Computed fields
  final int? durationDays;
  final bool? isMultiDay;
  final String? locationDisplay;

  // Related objects
  final int? streamId;
  final Map<String, dynamic>? streamDetail;
  final int? aicertsCourseId;
  final Map<String, dynamic>? aicertsCourseDetail;

  // Image/Media
  final String? imageUrl;
  final String? thumbnailUrl;

  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? lastUpdated;

  Masterclass({
    required this.id,
    required this.title,
    required this.slug,
    required this.masterclassType,
    required this.streamType,
    this.tier,
    this.focusArea,
    this.targetAudience,
    this.description,
    this.priceUsd,
    this.localPrice,
    this.formattedPriceStr,
    this.formattedPricePhysical,
    this.formattedPriceOnline,
    this.onlinePrice,
    this.physicalPrice,
    this.pricePhysicalUsd,
    this.priceOnlineUsd,
    this.isFeatured = false,
    this.active = true,
    this.launchPhase,
    this.hasOnlineOption = true, // Default to true

    // Location - comprehensive
    this.country,
    this.countryCode,
    this.countryName,
    this.city,
    this.venue,
    this.venueAddress,
    this.locations,

    // Dates
    this.startDate,
    this.endDate,

    // Additional fields
    this.category,
    this.currency,
    this.status,
    this.maxParticipants,
    this.currentParticipants,
    this.notes,

    // Computed
    this.durationDays,
    this.isMultiDay,
    this.locationDisplay,

    // Related
    this.streamId,
    this.streamDetail,
    this.aicertsCourseId,
    this.aicertsCourseDetail,

    // Image/Media
    this.imageUrl,
    this.thumbnailUrl,

    // Timestamps
    this.createdAt,
    this.updatedAt,
    this.lastUpdated,
  });

  factory Masterclass.fromJson(Map<String, dynamic> json) {
    // Parse dates
    DateTime? parseDate(String? dateString) {
      if (dateString == null) return null;
      try {
        return DateTime.tryParse(dateString);
      } catch (e) {
        return null;
      }
    }

    // Parse nested stream object
    int? streamId;
    Map<String, dynamic>? streamDetail;
    if (json['stream'] != null) {
      if (json['stream'] is int) {
        streamId = json['stream'] as int;
      } else if (json['stream'] is Map<String, dynamic>) {
        streamDetail = json['stream'] as Map<String, dynamic>;
        streamId = streamDetail['id'] as int?;
      }
    } else if (json['stream_detail'] != null) {
      streamDetail = json['stream_detail'] as Map<String, dynamic>;
      streamId = streamDetail['id'] as int?;
    }

    // Parse nested AICerts course object
    int? aicertsCourseId;
    Map<String, dynamic>? aicertsCourseDetail;
    if (json['aicerts_course'] != null) {
      if (json['aicerts_course'] is int) {
        aicertsCourseId = json['aicerts_course'] as int;
      } else if (json['aicerts_course'] is Map<String, dynamic>) {
        aicertsCourseDetail = json['aicerts_course'] as Map<String, dynamic>;
        aicertsCourseId = aicertsCourseDetail['id'] as int?;
      }
    } else if (json['aicerts_course_detail'] != null) {
      aicertsCourseDetail =
          json['aicerts_course_detail'] as Map<String, dynamic>;
      aicertsCourseId = aicertsCourseDetail['id'] as int?;
    }

    // Parse locations JSON field
    List<dynamic>? locations;
    if (json['locations'] != null) {
      if (json['locations'] is String) {
        try {
          // Now jsonDecode is available because we imported dart:convert
          locations = jsonDecode(json['locations']) as List<dynamic>;
        } catch (e) {
          locations = [];
        }
      } else if (json['locations'] is List<dynamic>) {
        locations = json['locations'] as List<dynamic>;
      }
    }

    return Masterclass(
      id: json['id'] as int,
      title: json['title'] != null
          ? _decodeHtml(json['title'] as String)
          : 'Untitled Masterclass',
      slug: json['slug'] as String? ?? '',
      masterclassType: json['masterclass_type'] as String? ?? '',
      streamType: json['stream_type'] as String? ?? 'professional',
      tier: json['tier'] as String?,
      focusArea: json['focus_area'] as String?,
      targetAudience: json['target_audience'] as String?,
      description: json['description'] != null
          ? _decodeHtml(json['description'] as String)
          : null,
      priceUsd: json['price_usd'] != null
          ? double.tryParse(json['price_usd'].toString())
          : null,
      localPrice: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      formattedPriceStr: json['formatted_price'] as String? ?? json['formatted_price_physical'] as String?,
      formattedPricePhysical: json['formatted_price_physical'] as String?,
      formattedPriceOnline: json['formatted_price_online'] as String?,
      onlinePrice: json['price_online'] != null
          ? double.tryParse(json['price_online'].toString())
          : json['price'] != null
              ? double.tryParse(json['price'].toString())
              : null,
      physicalPrice: json['price_physical'] != null
          ? double.tryParse(json['price_physical'].toString())
          : null,
      pricePhysicalUsd: json['price_physical_usd'] != null
          ? double.tryParse(json['price_physical_usd'].toString())
          : json['price_physical'] != null
              ? double.tryParse(json['price_physical'].toString())
              : null,
      priceOnlineUsd: json['price_online_usd'] != null
          ? double.tryParse(json['price_online_usd'].toString())
          : json['price'] != null
              ? double.tryParse(json['price'].toString())
              : null,
      isFeatured: json['is_featured'] as bool? ?? false,
      active: json['active'] as bool? ?? true,
      launchPhase: json['launch_phase'] as String?,
      hasOnlineOption: json['has_online_option'] as bool? ?? true,

      // Location fields - comprehensive parsing
      country: json['country'] as String?,
      countryCode: json['country_code'] as String?,
      countryName: json['country_name'] as String?,
      city: json['city'] as String? ?? json['location'] as String?,
      venue: json['venue'] as String?,
      venueAddress: json['venue_address'] as String?,
      locations: locations,

      // Date fields
      startDate: parseDate(json['start_date'] as String?),
      endDate: parseDate(json['end_date'] as String?),

      // Additional fields
      category: json['category'] as String?,
      currency: json['currency'] as String? ?? 'USD',
      status: json['status'] as String? ?? 'scheduled',
      maxParticipants: json['max_participants'] as int? ?? 35,
      currentParticipants: json['current_participants'] as int? ?? 0,
      notes: json['notes'] as String?,

      // Computed fields
      durationDays: json['duration_days'] as int?,
      isMultiDay: json['is_multi_day'] as bool?,
      locationDisplay: json['location_display'] as String?,

      // Related fields
      streamId: streamId,
      streamDetail: streamDetail,
      aicertsCourseId: aicertsCourseId,
      aicertsCourseDetail: aicertsCourseDetail,

      // Image/Media
      imageUrl:
          json['feature_image_url'] as String? ?? json['image_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,

      // Timestamps
      createdAt: parseDate(json['created_at'] as String?),
      updatedAt: parseDate(json['updated_at'] as String?),
      lastUpdated: json['last_updated'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'masterclass_type': masterclassType,
      'stream_type': streamType,
      'tier': tier,
      'focus_area': focusArea,
      'target_audience': targetAudience,
      'description': description,
      'price_usd': priceUsd,
      'price_physical_usd': pricePhysicalUsd,
      'price_online_usd': priceOnlineUsd,
      'is_featured': isFeatured,
      'active': active,
      'launch_phase': launchPhase,

      // Location - comprehensive
      'country': country,
      'country_code': countryCode,
      'country_name': countryName,
      'city': city,
      'venue': venue,
      'venue_address': venueAddress,
      'locations': locations,

      // Dates
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),

      // Additional fields
      'category': category,
      'currency': currency,
      'status': status,
      'max_participants': maxParticipants,
      'current_participants': currentParticipants,
      'notes': notes,

      // Computed (usually read-only)
      'duration_days': durationDays,
      'is_multi_day': isMultiDay,
      'location_display': locationDisplay,

      // Related (IDs only for sending)
      'stream': streamId,
      'aicerts_course': aicertsCourseId,

      // Image/Media
      'image_url': imageUrl,
      'thumbnail_url': thumbnailUrl,

      // Timestamps (read-only)
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ─── HELPER METHODS ──────────────────────────────────────────────

  /// Get explicit price from API (e.g., $5 special masterclass)
  /// Returns null if not set, in which case use calculated price
  /// Priority: pricePhysicalUsd (for consistency with enrollment display) > priceUsd
  double? get price {
    // Priority: pricePhysicalUsd (USD) -> physicalPrice (localized) -> priceUsd (legacy)
    if (pricePhysicalUsd != null && pricePhysicalUsd! > 0) return pricePhysicalUsd;
    if (physicalPrice != null && physicalPrice! > 0) return physicalPrice;
    return priceUsd;
  }

  // Note: physicalPrice is now a property mapped from JSON.

  /// Get online attendance price - Strictly from database
  double? get onlinePriceCalculated {
    if (priceOnlineUsd != null && priceOnlineUsd! > 0) {
      return priceOnlineUsd!;
    }
    return null; // No fallback to constants
  }

  /// HARDENED: Get formatted price for physical attendance
  String get formattedPhysicalPrice {
    if (formattedPricePhysical != null) return formattedPricePhysical!;
    final price = physicalPrice;
    if (price == null) return 'Contact for pricing';
    return _formatPriceLocalized(price);
  }

  /// HARDENED: Get formatted price for online attendance
  String get formattedOnlinePrice {
    if (formattedPriceOnline != null) return formattedPriceOnline!;
    final price = onlinePriceCalculated;
    if (price == null) return 'Contact for pricing';
    return _formatPriceLocalized(price);
  }

  /// HARDENED: Format price with local currency - never show USD
  String _formatPriceLocalized(double priceUsd) {
    // HARDENED: Always convert through CurrencyService
    // This ensures prices are always in local currency, never USD
    try {
      return CurrencyService.instance.formatUSDAmount(priceUsd);
    } catch (e) {
      // If conversion fails, return contact message rather than showing USD
      return 'Contact for pricing';
    }
  }

  String get formattedPrice {
    // Aligned with database: Priority to specific localized string, then physical price, then online
    if (formattedPriceStr != null) return formattedPriceStr!;
    
    final mainPrice = price; // This already prioritizes physical over online
    if (mainPrice != null) return _formatPriceLocalized(mainPrice);
    
    return 'Contact for pricing';
  }

  String _getCurrencySymbol() {
    switch (currency?.toUpperCase()) {
      case 'KES':
        return 'KSh';
      case 'NGN':
        return '₦';
      case 'GHS':
        return 'GH₵';
      case 'ZAR':
        return 'R';
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

  String get formattedDuration {
    if (durationDays == null) return 'Duration not set';
    return '$durationDays day${durationDays! > 1 ? 's' : ''}';
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

  bool get isPast {
    if (endDate == null) return false;
    return endDate!.isBefore(DateTime.now());
  }

  // NEW: Get seats remaining
  int get seatsRemaining {
    if (maxParticipants == null || currentParticipants == null) return 0;
    return (maxParticipants! - currentParticipants!).clamp(0, maxParticipants!);
  }

  // NEW: Check if masterclass is full
  bool get isFull {
    if (maxParticipants == null || currentParticipants == null) return false;
    return currentParticipants! >= maxParticipants!;
  }

  // NEW: Get location display with fallback
  String get displayLocation {
    if (locationDisplay != null && locationDisplay!.isNotEmpty) {
      return locationDisplay!;
    }

    if (city != null && countryName != null) {
      return '$city, $countryName';
    } else if (city != null) {
      return city!;
    } else if (countryName != null) {
      return countryName!;
    } else if (country != null) {
      return country!;
    }

    return 'Location not specified';
  }

  // NEW: Get status display name (without color)
  String get statusDisplay {
    switch (status?.toLowerCase()) {
      case 'scheduled':
        return 'Scheduled';
      case 'ongoing':
        return 'Ongoing';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Scheduled';
    }
  }

  // NEW: Get stream type display
  String get streamTypeDisplay {
    switch (streamType.toLowerCase()) {
      case 'professional':
        return 'Professional';
      case 'technical':
        return 'Technical';
      default:
        return streamType;
    }
  }

  // NEW: Get tier display
  String get tierDisplay {
    switch (tier?.toLowerCase()) {
      case 'basic':
        return 'Basic';
      case 'standard':
        return 'Standard';
      case 'premium':
        return 'Premium';
      case 'tier_1':
        return 'Tier 1';
      case 'tier_2':
        return 'Tier 2';
      case 'tier_3':
        return 'Tier 3';
      default:
        return tier ?? 'Standard';
    }
  }

  // ─── COPY WITH METHOD ───────────────────────────────────────────

  Masterclass copyWith({
    int? id,
    String? title,
    String? slug,
    String? masterclassType,
    String? streamType,
    String? tier,
    String? focusArea,
    String? targetAudience,
    String? description,
    double? priceUsd,
    double? pricePhysicalUsd,
    double? priceOnlineUsd,
    double? onlinePrice,
    bool? isFeatured,
    bool? active,
    String? launchPhase,
    bool? hasOnlineOption,
    String? country,
    String? countryCode,
    String? countryName,
    String? city,
    String? venue,
    String? venueAddress,
    List<dynamic>? locations,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? currency,
    String? status,
    int? maxParticipants,
    int? currentParticipants,
    String? notes,
    int? durationDays,
    bool? isMultiDay,
    String? locationDisplay,
    int? streamId,
    Map<String, dynamic>? streamDetail,
    int? aicertsCourseId,
    Map<String, dynamic>? aicertsCourseDetail,
    String? imageUrl,
    String? thumbnailUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastUpdated,
  }) {
    return Masterclass(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      masterclassType: masterclassType ?? this.masterclassType,
      streamType: streamType ?? this.streamType,
      tier: tier ?? this.tier,
      focusArea: focusArea ?? this.focusArea,
      targetAudience: targetAudience ?? this.targetAudience,
      description: description ?? this.description,
      priceUsd: priceUsd ?? this.priceUsd,
      pricePhysicalUsd: pricePhysicalUsd ?? this.pricePhysicalUsd,
      priceOnlineUsd: priceOnlineUsd ?? this.priceOnlineUsd,
      onlinePrice: onlinePrice ?? this.onlinePrice,
      isFeatured: isFeatured ?? this.isFeatured,
      active: active ?? this.active,
      launchPhase: launchPhase ?? this.launchPhase,
      hasOnlineOption: hasOnlineOption ?? this.hasOnlineOption,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      city: city ?? this.city,
      venue: venue ?? this.venue,
      venueAddress: venueAddress ?? this.venueAddress,
      locations: locations ?? this.locations,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      notes: notes ?? this.notes,
      durationDays: durationDays ?? this.durationDays,
      isMultiDay: isMultiDay ?? this.isMultiDay,
      locationDisplay: locationDisplay ?? this.locationDisplay,
      streamId: streamId ?? this.streamId,
      streamDetail: streamDetail ?? this.streamDetail,
      aicertsCourseId: aicertsCourseId ?? this.aicertsCourseId,
      aicertsCourseDetail: aicertsCourseDetail ?? this.aicertsCourseDetail,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Masterclass &&
        other.id == id &&
        other.title == title &&
        other.slug == slug;
  }

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ slug.hashCode;

  @override
  String toString() {
    return 'Masterclass(id: $id, title: "$title", streamType: $streamType, location: $displayLocation, status: $status)';
  }

  // Convert Masterclass to Course for cart/wishlist compatibility
  Course toCourse() {
    return Course(
      id: id.toString(),
      title: title,
      description: description,
      featureImageUrl: imageUrl ?? thumbnailUrl,
      price: priceUsd,
      startDate: startDate,
      endDate: endDate,
      status: status,
      instructorName: streamDetail?['name'] as String?,
      durationHours:
          durationDays != null ? durationDays! * 8 : null, // Approx 8 hours/day
      roleType: 'Masterclass',
      certificationLevel: tier,
      industry: streamType,
      city: city,
      country: country,
      countryCode: countryCode,
    );
  }

  static String _decodeHtml(String html) {
    if (html.isEmpty) return html;
    final htmlTagRegExp =
        RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return html
        .replaceAll(htmlTagRegExp, '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#8211;', '-') // En-dash
        .replaceAll('&#8212;', '--') // Em-dash
        .replaceAll('&#8216;', "'") // Left single quote
        .replaceAll('&#8217;', "'") // Right single quote
        .replaceAll('&#8220;', '"') // Left double quote
        .replaceAll('&#8221;', '"') // Right double quote
        .replaceAll('&trade;', '™')
        .replaceAll('&reg;', '®')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

// ─── LIST RESPONSE ────────────────────────────────────────────────

class MasterclassListResponse {
  final List<Masterclass> masterclasses;
  final int count;
  final String? next;
  final String? previous;

  MasterclassListResponse({
    required this.masterclasses,
    required this.count,
    this.next,
    this.previous,
  });

  factory MasterclassListResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> results = json['results'] ?? [];
    return MasterclassListResponse(
      masterclasses: results
          .map((item) => Masterclass.fromJson(item as Map<String, dynamic>))
          .toList(),
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
    );
  }
}
