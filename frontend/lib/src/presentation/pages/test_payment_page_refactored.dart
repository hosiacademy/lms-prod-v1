// test_payment_page_refactored.dart
/// Refactored test payment page using the responsive design system
/// This demonstrates that the responsive system integrates correctly
/// with existing Flutter Web LMS pages.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import responsive system using barrel exports
import 'package:frontend/src/core/utils/utils.dart';
import 'package:frontend/src/core/theme/theme.dart';
import 'package:frontend/src/presentation/widgets/responsive/responsive_system.dart';

// Import existing payment-related modules
import '../../data/datasources/payment_service.dart';
import '../blocs/payment/payment_bloc.dart';
import 'onboarding/models/payment_enums.dart';

/// Refactored Test Payment Page using Responsive Design System
/// 
/// This page demonstrates:
/// - Responsive layout that adapts to mobile/tablet/desktop
/// - Using ResponsiveHelper for breakpoint detection
/// - Using ResponsiveButton for adaptive button sizing
/// - Using AppDesignSystem for consistent spacing and typography
/// - Using ResponsiveGrid for responsive layout
/// - Using ResponsiveContainer for max-width constraint
/// 
/// The responsive system ensures this page works beautifully on:
/// - Mobile devices (< 600px): Single column layout, touch-friendly buttons
/// - Tablets (600-1024px): Two column layout, medium buttons
/// - Desktops (≥ 1024px): Three column layout, full-size buttons
class TestPaymentPageRefactored extends StatelessWidget {
  const TestPaymentPageRefactored({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Payment System Test'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ResponsiveContainer(
        maxWidth: 1200,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppDesignSystem.lg),
            child: ResponsiveGrid(
              mobileColumns: 1,
              tabletColumns: ResponsiveHelper.isTablet(context) ? 2 : 1,
              desktopColumns: 3,
              mainAxisSpacing: AppDesignSystem.lg,
              crossAxisSpacing: AppDesignSystem.lg,
              children: [
                // Card 1: Header/Title Section
                _buildHeaderCard(context),
                
                // Card 2: Payment Methods Info
                _buildPaymentMethodsCard(context),
                
                // Card 3: Payment Status Info
                _buildPaymentStatusCard(context),
                
                // Card 4: Test Payment Service
                _buildTestServiceCard(context),
                
                // Card 5: Test Payment Bloc
                _buildTestBlocCard(context),
                
                // Card 6: System Status
                _buildSystemStatusCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Header/Title Card Section
  Widget _buildHeaderCard(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ResponsiveText(
            'Payment System Test',
            baseStyle: TextStyle(
              fontSize: ResponsiveHelper.h1(context),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: AppDesignSystem.md),
          ResponsiveText(
            'Testing the responsive payment system integration',
            baseStyle: TextStyle(
              fontSize: ResponsiveHelper.body(context),
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Payment Methods Information Card
  Widget _buildPaymentMethodsCard(BuildContext context) {
    final paymentMethods = PaymentMethod.values.length;
    
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Payment Methods',
            baseStyle: TextStyle(
              fontSize: ResponsiveHelper.h3(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDesignSystem.md),
          Container(
            padding: const EdgeInsets.all(AppDesignSystem.md),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusMD),
            ),
            child: ResponsiveText(
              'Total Methods: $paymentMethods',
              baseStyle: TextStyle(
                fontSize: ResponsiveHelper.body(context),
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppDesignSystem.md),
          ResponsiveButton(
            label: 'View Methods',
            onPressed: () {
              // Implementation would go here
            },
          ),
        ],
      ),
    );
  }

  /// Payment Status Information Card
  Widget _buildPaymentStatusCard(BuildContext context) {
    final paymentStatuses = PaymentStatus.values.length;
    
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Payment Statuses',
            baseStyle: TextStyle(
              fontSize: ResponsiveHelper.h3(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDesignSystem.md),
          Container(
            padding: const EdgeInsets.all(AppDesignSystem.md),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusMD),
            ),
            child: ResponsiveText(
              'Total Statuses: $paymentStatuses',
              baseStyle: TextStyle(
                fontSize: ResponsiveHelper.body(context),
                color: Colors.green.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppDesignSystem.md),
          ResponsiveButton(
            label: 'View Statuses',
            onPressed: () {
              // Implementation would go here
            },
          ),
        ],
      ),
    );
  }

  /// Test Payment Service Card
  Widget _buildTestServiceCard(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Test Payment Service',
            baseStyle: TextStyle(
              fontSize: ResponsiveHelper.h3(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDesignSystem.md),
          ResponsiveText(
            'Click to initialize and test the payment service',
            baseStyle: TextStyle(
              fontSize: ResponsiveHelper.body(context),
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppDesignSystem.lg),
          ResponsiveButton(
            label: 'Test Payment Service',
            variant: ButtonVariant.primary,
            onPressed: () {
              // Test payment service
              final paymentService = context.read<PaymentService>();
              debugPrint(
                'PaymentService initialized: ${paymentService.runtimeType}',
              );
              
              // Show snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'PaymentService: ${paymentService.runtimeType}',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Test Payment Bloc Card
  Widget _buildTestBlocCard(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Test Payment Bloc',
            baseStyle: TextStyle(
              fontSize: ResponsiveHelper.h3(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDesignSystem.md),
          ResponsiveText(
            'Click to initialize and test the payment bloc',
            baseStyle: TextStyle(
              fontSize: ResponsiveHelper.body(context),
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppDesignSystem.lg),
          ResponsiveButton(
            label: 'Test Payment Bloc',
            variant: ButtonVariant.secondary,
            onPressed: () {
              // Test payment bloc
              final paymentBloc = context.read<PaymentBloc>();
              debugPrint(
                'PaymentBloc initialized: ${paymentBloc.runtimeType}',
              );
              
              // Show snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'PaymentBloc: ${paymentBloc.runtimeType}',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// System Status Card
  Widget _buildSystemStatusCard(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final screenWidth = MediaQuery.of(context).size.width.toStringAsFixed(0);
    
    String deviceType = 'Unknown';
    if (isMobile) deviceType = 'Mobile';
    else if (isTablet) deviceType = 'Tablet';
    else if (isDesktop) deviceType = 'Desktop';
    
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'System Status',
            baseStyle: TextStyle(
              fontSize: ResponsiveHelper.h3(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDesignSystem.md),
          _buildStatusRow('Device Type:', deviceType, Colors.blue),
          const SizedBox(height: AppDesignSystem.sm),
          _buildStatusRow('Screen Width:', '${screenWidth}px', Colors.purple),
          const SizedBox(height: AppDesignSystem.sm),
          _buildStatusRow('Responsive System:', 'Active ✓', Colors.green),
          const SizedBox(height: AppDesignSystem.md),
          ResponsiveText(
            'This page adapts automatically to your device size.',
            baseStyle: TextStyle(
              fontSize: ResponsiveHelper.caption(context),
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper to build status rows
  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusMD),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
