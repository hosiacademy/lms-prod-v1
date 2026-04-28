import 'package:flutter/material.dart';
import '../../../../../data/models/masterclass.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../widgets/modals/multi_step_enrollment_modal.dart';

class MasterclassEnrollment {
  static void startEnrollment({
    required BuildContext context,
    required Masterclass masterclass,
    required VoidCallback onPaymentComplete,
  }) {
    _showEnrollmentWizard(context, masterclass, onPaymentComplete);
  }

  static void _showEnrollmentWizard(
    BuildContext context,
    Masterclass masterclass,
    VoidCallback onPaymentComplete,
  ) async {
    // Check if user is authenticated (has active JWT token)
    final isAuthenticated = await AuthService.isAuthenticated();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return MultiStepEnrollmentModal(
          masterclass: masterclass,
          onEnrollmentComplete: onPaymentComplete,
          allowPrefill: isAuthenticated, // Only pre-fill if user is logged in
        );
      },
    );
  }
}
