class Promotion {
  final int id;
  final String title;
  final String description;
  final String promotionType;
  final String? imageUrl;
  final String backgroundColor;
  final String textColor;
  final String icon;
  final double? discountPercentage;
  final String ctaText;
  final String? ctaUrl;
  final DateTime startDate;
  final DateTime endDate;
  final int priority;
  final bool showOnOnboarding;
  final bool isCurrentlyActive;
  final int daysRemaining;

  const Promotion({
    required this.id,
    required this.title,
    required this.description,
    required this.promotionType,
    this.imageUrl,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    this.discountPercentage,
    required this.ctaText,
    this.ctaUrl,
    required this.startDate,
    required this.endDate,
    required this.priority,
    required this.showOnOnboarding,
    required this.isCurrentlyActive,
    required this.daysRemaining,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      promotionType: json['promotion_type'] as String? ?? 'discount',
      imageUrl: json['image_url'] as String?,
      backgroundColor: json['background_color'] as String? ?? '#FF5722',
      textColor: json['text_color'] as String? ?? '#FFFFFF',
      icon: json['icon'] as String? ?? '🎉',
      discountPercentage: json['discount_percentage'] != null
          ? double.tryParse(json['discount_percentage'].toString())
          : null,
      ctaText: json['cta_text'] as String? ?? 'Learn More',
      ctaUrl: json['cta_url'] as String?,
      startDate: DateTime.tryParse(json['start_date'] as String? ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['end_date'] as String? ?? '') ?? DateTime.now(),
      priority: json['priority'] as int? ?? 0,
      showOnOnboarding: json['show_on_onboarding'] as bool? ?? true,
      isCurrentlyActive: json['is_currently_active'] as bool? ?? false,
      daysRemaining: json['days_remaining'] as int? ?? 0,
    );
  }
}
