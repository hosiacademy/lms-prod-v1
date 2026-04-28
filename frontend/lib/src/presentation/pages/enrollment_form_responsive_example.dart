/// Example Enrollment Form using Responsive Design System
/// 
/// This demonstrates how to create responsive forms that adapt to screen size.
/// The form stacks vertically on mobile but displays side-by-side on desktop.

import 'package:flutter/material.dart';
import '../../core/utils/utils.dart';
import '../../core/theme/theme.dart';
import '../widgets/responsive/responsive_system.dart';

class EnrollmentFormResponsiveExample extends StatefulWidget {
  const EnrollmentFormResponsiveExample({Key? key}) : super(key: key);

  @override
  State<EnrollmentFormResponsiveExample> createState() =>
      _EnrollmentFormResponsiveExampleState();
}

class _EnrollmentFormResponsiveExampleState
    extends State<EnrollmentFormResponsiveExample> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enroll in Course'),
      ),
      body: SingleChildScrollView(
        child: ResponsiveContainer(
          maxWidth: 800, // Constrains form width on desktop
          child: Padding(
            padding: EdgeInsets.all(AppDesignSystem.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  ResponsiveText(
                    'Course Enrollment',
                    baseStyle: TextStyle(
                      fontSize: ResponsiveHelper.h2(context),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.hosiMidnight,
                    ),
                  ),

                  SizedBox(height: AppDesignSystem.md),

                  ResponsiveText(
                    'Fill in your details to enroll in this course.',
                    baseStyle: TextStyle(
                      fontSize: ResponsiveHelper.body(context),
                      color: Colors.grey[600],
                    ),
                  ),

                  SizedBox(height: AppDesignSystem.lg),

                  // Two-column layout: stacks on mobile, side-by-side on desktop
                  ResponsiveFlexRow(
                    children: [
                      (
                        child: ResponsiveFormField(
                          label: 'Full Name',
                          child: ResponsiveTextField(
                            label: 'Full Name',
                            controller: _nameController,
                            onChanged: (value) {
                              // Validate
                            },
                          ),
                        ),
                        flex: 50,
                      ),
                      (
                        child: ResponsiveFormField(
                          label: 'Email Address',
                          child: ResponsiveTextField(
                            label: 'Email Address',
                            controller: _emailController,
                            onChanged: (value) {
                              // Validate
                            },
                          ),
                        ),
                        flex: 50,
                      ),
                    ],
                  ),

                  SizedBox(height: AppDesignSystem.lg),

                  // Full-width fields
                  ResponsiveFormField(
                    label: 'Phone Number',
                    child: ResponsiveTextField(
                      label: 'Phone Number',
                      onChanged: (value) {},
                    ),
                  ),

                  SizedBox(height: AppDesignSystem.lg),

                  ResponsiveFormField(
                    label: 'Country',
                    child: ResponsiveTextField(
                      label: 'Country',
                      onChanged: (value) {},
                    ),
                  ),

                  SizedBox(height: AppDesignSystem.xl),

                  // Terms and conditions checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: true,
                        onChanged: (value) {},
                      ),
                      Expanded(
                        child: ResponsiveText(
                          'I agree to the terms and conditions',
                          baseStyle: TextStyle(
                            fontSize: ResponsiveHelper.body(context),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: AppDesignSystem.lg),

                  // Action buttons - responsive
                  ResponsiveFlexRow(
                    children: [
                      (
                        child: ResponsiveButton(
                          label: 'Cancel',
                          variant: ButtonVariant.outline,
                          onPressed: () => Navigator.pop(context),
                        ),
                        flex: 50,
                      ),
                      (
                        child: ResponsiveButton(
                          label: 'Enroll',
                          variant: ButtonVariant.primary,
                          onPressed: _submitForm,
                        ),
                        flex: 50,
                      ),
                    ],
                  ),

                  SizedBox(height: AppDesignSystem.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Submit form
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enrollment successful!')),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// RESPONSIVE PATTERN: FORM LAYOUT
// ─────────────────────────────────────────────────────────────────────────
//
// This example shows how to create responsive forms using ResponsiveFlexRow:
//
// MOBILE (< 600px):
// - Full-width form (100% width)
// - Fields stack vertically
// - Buttons stack vertically
// - Touch-friendly (44px+ buttons)
//
// TABLET (600-1024px):
// - Still full-width but with more padding
// - Some fields can be 2-column
// - Buttons side-by-side
//
// DESKTOP (≥ 1024px):
// - Max-width 800px centered
// - Two-column layout for related fields
// - Buttons side-by-side with flex ratios
//
// ─────────────────────────────────────────────────────────────────────────
// KEY RESPONSIVE TECHNIQUES USED
// ─────────────────────────────────────────────────────────────────────────
//
// 1. ResponsiveContainer(maxWidth: 800)
//    - Prevents form from being too wide on desktop
//    - Ensures optimal reading width
//
// 2. ResponsiveFlexRow for two-column layout
//    - Mobile: stacks vertically (100% each)
//    - Desktop: 50/50 side-by-side
//
// 3. ResponsiveTextField for inputs
//    - Mobile: 36px height
//    - Desktop: 44px height
//
// 4. ResponsiveButton for actions
//    - Mobile: 44px height (touch-friendly)
//    - Desktop: 48px height
//
// 5. ResponsiveSpacer for spacing
//    - Mobile: 12px gaps
//    - Desktop: 16-24px gaps
//
// 6. ResponsiveText for typography
//    - Scales font sizes automatically
//    - Maintains readability at all sizes
//
// ─────────────────────────────────────────────────────────────────────────
// TESTING CHECKLIST
// ─────────────────────────────────────────────────────────────────────────
//
// Test on:
// - Mobile (375px): Form full-width, fields stack, buttons stack
// - Mobile landscape (812px): Two fields per row, buttons side-by-side
// - Tablet (768px): Max-width visible, fields two-column
// - Desktop (1440px): Centered with max-width, optimal reading width
//
// Verify:
// - No horizontal scroll
// - Fields responsive width
// - Buttons touch-friendly (44px+)
// - Text readable at all sizes
// - Spacing consistent
// - Form submits properly
//
// ─────────────────────────────────────────────────────────────────────────
