// lib/src/core/services/enrollment_service.dart

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../../data/models/enrollment.dart'; // Your Enrollment model

class EnrollmentResult {
  final bool success;
  final String? enrollmentId;
  final String? message;
  final Object? error;

  const EnrollmentResult.success({
    required this.enrollmentId,
  })  : success = true,
        message = null,
        error = null;

  const EnrollmentResult.failure({
    this.message,
    this.error,
  })  : success = false,
        enrollmentId = null;

  @override
  String toString() {
    if (success) return 'Enrollment success: ID $enrollmentId';
    return 'Enrollment failed: ${message ?? error}';
  }
}

/// Handles real enrollment logic after successful payment.
///
/// Key behaviors:
/// - Masterclass / Industry → immediate full enrollment
/// - Learnership → provisional enrollment → admin verification → confirm or reimburse
class EnrollmentService {
  /// Finalizes enrollment after payment confirmation.
  ///
  /// Returns [EnrollmentResult] with either success (with enrollment ID)
  /// or detailed failure reason.
  static Future<EnrollmentResult> finalizeAfterPayment({
    required String programType, // 'masterclass', 'industry', 'learnership'
    required int programId,
    required String transactionReference,
    required Map<String, dynamic> userData,
    required bool isCorporate,
    String? companyName,
    String? companyRegNumber,
    String? companyVat,
    String? contactPerson,
  }) async {
    try {
      // 1. Create / ensure user exists in AICERTS / Moodle
      final userResponse = await ApiClient.createUser(
        firstName: userData['first_name']?.toString() ?? '',
        lastName: userData['last_name']?.toString() ?? '',
        email: userData['email']?.toString() ?? '',
        username: userData['email']?.toString() ?? '',
        // Add more fields when your API supports them:
        // idNumber, phone, dob, gender, etc.
      );

      final String? userId = userResponse['id']?.toString();
      if (userId == null || userId.isEmpty) {
        return EnrollmentResult.failure(
          message: 'Failed to create or retrieve user in AICERTS',
        );
      }

      // 2. Enroll user in the program (AICERTS / Moodle)
      await ApiClient.enrollUserInCourse(
        userId: userId,
        courseId: programId,
      );

      // 3. Create local enrollment record
      final enrollment = Enrollment(
        id: 'enroll-${DateTime.now().millisecondsSinceEpoch}',
        courseId: programId.toString(),
        courseName:
            userData['program_name']?.toString() ?? 'Program $programId',
        courseType: programType,
        status: programType == 'learnership'
            ? EnrollmentStatus
                .suspended // provisional = suspended until verified
            : EnrollmentStatus.active,
        enrolledAt: DateTime.now(),
        progress: 0.0,
        thumbnailUrl: userData['thumbnail_url']?.toString(),
        hasCommunityChat: true,
        chatRoomId: 'chat-$programId-$userId',
      );

      // 4. Learnership-specific: create provisional record in your backend
      if (programType == 'learnership') {
        final companyData = isCorporate
            ? {
                'name': companyName,
                'registration_number': companyRegNumber,
                'vat_number': companyVat,
                'contact_person': contactPerson,
              }
            : null;

        final provisionalResponse =
            await ApiClient.createProvisionalLearnershipEnrollment(
          programId: programId,
          userId: userId,
          transactionReference: transactionReference,
          expiresInDays: 7,
          isCorporate: isCorporate,
          companyData: companyData,
        );

        // Update enrollment ID with the provisional one from backend
        final provisionalId = provisionalResponse['id']?.toString();
        if (provisionalId != null) {
          // You could store provisionalId somewhere or link it
          debugPrint('Provisional enrollment created: ID $provisionalId');
        }
      }

      debugPrint(
          'Enrollment completed → user: $userId, program: $programId ($programType)');
      return EnrollmentResult.success(enrollmentId: enrollment.id);
    } catch (e, stackTrace) {
      debugPrint('Enrollment failed: $e');
      debugPrint('Stack: $stackTrace');
      return EnrollmentResult.failure(
        message: 'Enrollment processing failed',
        error: e,
      );
    }
  }

  /// Finalizes or cancels a provisional learnership enrollment after admin review.
  ///
  /// - If prerequisitesMet → activates full enrollment
  /// - If not → reimburses payment and marks enrollment as cancelled/refunded
  static Future<EnrollmentResult> processLearnershipVerification({
    required int provisionalId,
    required bool prerequisitesMet,
    String? rejectionReason,
  }) async {
    try {
      if (prerequisitesMet) {
        // Activate full enrollment in your backend
        await ApiClient.confirmProvisionalLearnershipEnrollment(provisionalId);

        // Optionally update local status to active
        // You would typically do this in your repository/bloc

        debugPrint(
            'Provisional enrollment #$provisionalId → full enrollment confirmed');
        return EnrollmentResult.success(enrollmentId: provisionalId.toString());
      } else {
        // Get transaction reference
        final provisionalData =
            await ApiClient.getProvisionalLearnershipEnrollment(provisionalId);
        final String? transactionRef =
            provisionalData['transaction_reference']?.toString();

        if (transactionRef != null && transactionRef.isNotEmpty) {
          await ApiClient.reimbursePayment(transactionRef);
          debugPrint('Reimbursement processed for provisional #$provisionalId');
        } else {
          debugPrint(
              'Warning: No transaction reference found for ID $provisionalId');
        }

        // Mark enrollment as suspended/cancelled in your backend
        // await ApiClient.updateEnrollmentStatus(provisionalId, 'cancelled');

        return EnrollmentResult.failure(
          message: 'Prerequisites not met – payment reimbursed',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Verification processing failed: $e');
      debugPrint('Stack: $stackTrace');
      return EnrollmentResult.failure(
        message: 'Verification process failed',
        error: e,
      );
    }
  }
}
