// lib/src/presentation/widgets/modals/aicerts/aicerts_modals.dart
// Utility class for AICERTS enrollment - uses unified EnrollmentFormWidget

export 'shared/aicerts_form_data.dart';

import 'package:flutter/material.dart';
import '../../../../data/models/course.dart';
import '../../enrollment/enrollment_form_widget.dart';
import '../../../pages/payment/payment_provider_selection_page.dart';
import 'multi_step_aicerts_custom_selection_modal.dart';

/// AICERTS modal utilities and helpers
class AicertsModals {
  /// Show the appropriate AICERTS enrollment modal based on course type
  static Future<void> showEnrollmentModal({
    required BuildContext context,
    required List<Course> courses,
    String? industry,
    String? role,
    VoidCallback? onEnrollmentComplete,
  }) async {
    // Determine which modal to show based on context
    final courseType = courses.first.courseType;
    final isIndustryTraining = industry != null && industry != 'all';
    final isCustomSelection = courseType == 'custom_selection' || courses.length > 1;
    
    if (isIndustryTraining) {
      return _showIndustryTrainingModal(
        context: context,
        courses: courses,
        industry: industry!,
        role: role,
        onEnrollmentComplete: onEnrollmentComplete,
      );
    } else if (isCustomSelection) {
      return _showCustomSelectionModal(
        context: context,
        courses: courses,
        onEnrollmentComplete: onEnrollmentComplete,
      );
    } else {
      // Fallback to generic AICERTS modal (single course)
      return _showGenericAicertsModal(
        context: context,
        courses: courses,
        onEnrollmentComplete: onEnrollmentComplete,
      );
    }
  }

  /// Show industry training enrollment modal using MultiStepAICERTSCustomSelectionModal
  static Future<void> _showIndustryTrainingModal({
    required BuildContext context,
    required List<Course> courses,
    required String industry,
    String? role,
    VoidCallback? onEnrollmentComplete,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MultiStepAICERTSCustomSelectionModal(
        courses: courses,
        enrollmentType: 'industry_training',
        onEnrollmentComplete: onEnrollmentComplete,
      ),
    );
  }

  /// Show custom selection enrollment modal using MultiStepAICERTSCustomSelectionModal
  static Future<void> _showCustomSelectionModal({
    required BuildContext context,
    required List<Course> courses,
    VoidCallback? onEnrollmentComplete,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MultiStepAICERTSCustomSelectionModal(
        courses: courses,
        enrollmentType: 'custom_selection',
        onEnrollmentComplete: onEnrollmentComplete,
      ),
    );
  }

  /// Show generic AICERTS modal for single courses
  static Future<void> _showGenericAicertsModal({
    required BuildContext context,
    required List<Course> courses,
    VoidCallback? onEnrollmentComplete,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MultiStepAICERTSCustomSelectionModal(
        courses: courses,
        enrollmentType: 'single_course',
        onEnrollmentComplete: onEnrollmentComplete,
      ),
    );
  }

  /// Calculate total price for multiple courses
  static double _calculateCoursesTotal(List<Course> courses, {String? streamType}) {
    if (courses.isEmpty) return 0.0;
    
    double total = 0.0;
    for (final course in courses) {
      final effectiveStreamType = streamType ?? 
          (course.streamType ?? (course.industry?.toLowerCase().contains('technical') == true 
              ? 'technical' 
              : 'professional'));
      total += _calculateSingleCoursePrice(course, effectiveStreamType);
    }
    return total;
  }

  /// Check if courses are AICERTS-powered
  static bool areCoursesAicertsPowered(List<Course> courses) {
    if (courses.isEmpty) return false;
    
    // Check if any course has AICERTS-related data
    for (final course in courses) {
      if (course.courseType == 'industry_training' || 
          course.courseType == 'custom_selection' ||
          course.industry?.toLowerCase().contains('aicerts') == true ||
          course.description?.toLowerCase().contains('aicerts') == true) {
        return true;
      }
    }
    
    return false;
  }

  /// Get appropriate AICERTS pricing
  static double getAicertsPrice(List<Course> courses, {String? streamType}) {
    if (courses.isEmpty) return 0.0;
    
    // Use first course stream type if not specified
    final effectiveStreamType = streamType ?? 
        (courses.first.industry?.toLowerCase().contains('technical') == true 
            ? 'technical' 
            : 'professional');
    
    // Calculate total price
    double total = 0.0;
    for (final course in courses) {
      final pricingStreamType = effectiveStreamType;
      // This would use PricingConstants.getAICertsPrice() in implementation
      total += _calculateSingleCoursePrice(course, pricingStreamType);
    }
    return total;
  }

  static double _calculateSingleCoursePrice(Course course, String streamType) {
    // Aligned with database: Prioritize course.price from backend
    if (course.price != null && course.price! > 0) {
      return course.price!;
    }
    
    return 0.0; // Strictly from backend - no fallback to constants
  }
}