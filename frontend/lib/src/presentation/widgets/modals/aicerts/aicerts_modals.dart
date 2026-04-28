// lib/src/presentation/widgets/modals/aicerts/aicerts_modals.dart
// Utility class for AICERTS enrollment - uses unified EnrollmentFormWidget

export 'shared/aicerts_form_data.dart';

import 'package:flutter/material.dart';
import '../../../../data/models/course.dart';
import '../../enrollment/enrollment_form_widget.dart';
import '../../../pages/payment/payment_provider_selection_page.dart';

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

  /// Show industry training enrollment modal using EnrollmentFormWidget
  static Future<void> _showIndustryTrainingModal({
    required BuildContext context,
    required List<Course> courses,
    required String industry,
    String? role,
    VoidCallback? onEnrollmentComplete,
  }) async {
    final course = courses.first;
    final totalPrice = _calculateCoursesTotal(courses, streamType: course.streamType ?? 'technical');
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.school, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Enroll in ${course.title}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Enrollment form
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: EnrollmentFormWidget(
                    enrollmentType: 'industry_training',
                    trainingId: int.tryParse(course.id) ?? 0,
                    trainingTitle: course.title,
                    enrollmentFee: totalPrice,
                    currency: 'USD',
                    onSubmit: (enrollmentData) async {
                      if (enrollmentData['learner_full_name'] == null || 
                          enrollmentData['learner_email'] == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all required fields'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      try {
                        final enhancedData = {
                          ...enrollmentData,
                          'industry': industry != 'all' ? industry : 'general',
                          'role': role != 'all' ? role : null,
                          'course_type': 'aicerts_industry_training',
                          'stream_type': course.streamType ?? 'technical',
                        };
                        
                        await PaymentProviderSelectionPage.show(
                          context,
                          reference: 'IT-${course.id}-${DateTime.now().millisecondsSinceEpoch}',
                          amount: totalPrice,
                          currency: 'USD',
                          country: enrollmentData['selected_country'] != null ? 'ZA' : 'ZA',
                          programId: course.id.toString(),
                          programType: 'industry_training',
                          paymentMetadata: {
                            'industry': industry != 'all' ? industry : 'general',
                            'role': role != 'all' ? role : null,
                            'course_title': course.title,
                          },
                          enrollmentPayload: enhancedData,
                        );
                        
                        Navigator.of(context).pop();
                        onEnrollmentComplete?.call();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enrollment submitted successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    onCancel: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show custom selection enrollment modal using EnrollmentFormWidget
  static Future<void> _showCustomSelectionModal({
    required BuildContext context,
    required List<Course> courses,
    VoidCallback? onEnrollmentComplete,
  }) async {
    final totalPrice = _calculateCoursesTotal(courses);
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        courses.length == 1 
                          ? 'Enroll in ${courses.first.title}'
                          : 'Enroll in Custom Selection Package',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Enrollment form
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: EnrollmentFormWidget(
                    enrollmentType: 'custom_selection',
                    trainingId: int.tryParse(courses.first.id) ?? 0,
                    trainingTitle: courses.length == 1 
                      ? courses.first.title
                      : 'Custom Selection Package',
                    enrollmentFee: totalPrice,
                    currency: 'USD',
                    onSubmit: (enrollmentData) async {
                      if (enrollmentData['learner_full_name'] == null || 
                          enrollmentData['learner_email'] == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all required fields'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      try {
                        final enhancedData = {
                          ...enrollmentData,
                          'course_type': 'aicerts_custom_selection',
                          'course_count': courses.length,
                          'courses': courses.map((c) => c.id).toList(),
                          'course_titles': courses.map((c) => c.title).toList(),
                        };
                        
                        await PaymentProviderSelectionPage.show(
                          context,
                          reference: 'CS-${DateTime.now().millisecondsSinceEpoch}',
                          amount: totalPrice,
                          currency: 'USD',
                          country: enrollmentData['selected_country'] != null ? 'ZA' : 'ZA',
                          programId: 'custom_selection',
                          programType: 'custom_selection',
                          paymentMetadata: {
                            'course_count': courses.length,
                            'total_price': totalPrice,
                            'is_bundle': courses.length > 1,
                          },
                          enrollmentPayload: enhancedData,
                        );
                        
                        Navigator.of(context).pop();
                        onEnrollmentComplete?.call();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enrollment submitted successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    onCancel: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show generic AICERTS modal for single courses
  static Future<void> _showGenericAicertsModal({
    required BuildContext context,
    required List<Course> courses,
    VoidCallback? onEnrollmentComplete,
  }) async {
    // For single courses, treat as custom selection with one course
    return _showCustomSelectionModal(
      context: context,
      courses: courses,
      onEnrollmentComplete: onEnrollmentComplete,
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