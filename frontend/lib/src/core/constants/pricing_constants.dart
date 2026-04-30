// pricing_constants.dart
// Centralized pricing model for all courses and training programs
// All prices in USD - will be converted to local currency for display

/// Pricing constants in USD
class PricingConstants {
  // FALLBACK PRICING (Only used if database values are missing)
  // These should be kept in sync with the database defaults
  static const double masterclassTechnicalPhysical = 1100.0;
  static const double masterclassTechnicalOnline = 700.0;
  static const double masterclassProfessionalPhysical = 470.0;
  static const double masterclassProfessionalOnline = 320.0;

  // AICERTS course pricing based on stream type
  static const double aicertsTechnical = 420.0;
  static const double aicertsProfessional = 250.0;

  // Learnership pricing - Cybersecurity 2026 Intake
  // Formula: (Cert Cost + Platform $240 + Instructor $600) × 1.5 markup
  // Platform: $20/month × 12 = $240
  // Instructor: $50/month × 12 = $600
  static const double learnershipPlatformFee = 240.0;
  static const double learnershipInstructorFee = 600.0;
  static const double learnershipMarkupMultiplier = 1.5;

  // Certification costs per role
  static const double learnershipSOCAnalystCertCost = 6900.0;
  static const double learnershipSecurityEngineerCertCost = 5871.0;
  static const double learnershipSecurityConsultantCertCost = 7087.0;
  static const double learnershipRedTeamerCertCost = 9577.0;
  static const double learnershipBlueTeamerCertCost = 8095.0;
  static const double learnershipBugHunterCertCost = 7983.0;

  /// Get learnership price based on role/specialization
  static double getLearnershipPrice({
    required String role,
  }) {
    final roleLower = role.toLowerCase().replaceAll(' ', '_');
    
    // Calculate total cost and apply markup
    double certCost;
    if (roleLower.contains('soc') || roleLower.contains('analyst')) {
      certCost = learnershipSOCAnalystCertCost;
    } else if (roleLower.contains('engineer')) {
      certCost = learnershipSecurityEngineerCertCost;
    } else if (roleLower.contains('consultant')) {
      certCost = learnershipSecurityConsultantCertCost;
    } else if (roleLower.contains('red')) {
      certCost = learnershipRedTeamerCertCost;
    } else if (roleLower.contains('blue')) {
      certCost = learnershipBlueTeamerCertCost;
    } else if (roleLower.contains('bug') || roleLower.contains('hunter')) {
      certCost = learnershipBugHunterCertCost;
    } else {
      // Default to SOC Analyst pricing
      certCost = learnershipSOCAnalystCertCost;
    }
    
    final totalCost = certCost + learnershipPlatformFee + learnershipInstructorFee;
    return totalCost * learnershipMarkupMultiplier;
  }

  /// Get monthly learnership price (sales price ÷ 12)
  static double getLearnershipMonthlyPrice({
    required String role,
  }) {
    return getLearnershipPrice(role: role) / 12.0;
  }

  /// Get masterclass price based on stream type and attendance mode
  static double getMasterclassPrice({
    required String streamType,
    required bool isOnline,
  }) {
    final isTechnical = streamType.toLowerCase() == 'technical';
    
    if (isTechnical) {
      return isOnline ? masterclassTechnicalOnline : masterclassTechnicalPhysical;
    } else {
      return isOnline ? masterclassProfessionalOnline : masterclassProfessionalPhysical;
    }
  }

  /// Get AICERTS course price based on stream type
  static double getAICertsPrice({
    required String streamType,
  }) {
    final isTechnical = streamType.toLowerCase() == 'technical';
    return isTechnical ? aicertsTechnical : aicertsProfessional;
  }

  /// Check if a currency code is USD or USD-pegged
  static bool isUSDBasedCurrency(String currencyCode) {
    final upper = currencyCode.toUpperCase();
    // These currencies are USD-pegged or equivalent
    return upper == 'USD' || upper == 'ZWL' || upper == 'USDC';
  }
}
