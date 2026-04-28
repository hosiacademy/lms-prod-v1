// lib/src/presentation/pages/onboarding/cybersecurity_learnerships/cybersecurity_learnerships_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../learnerships/learnership_enrollment_page.dart';

/// Cybersecurity Learnerships Page
/// Shows ONLY learnerships with category = 'Cybersecurity'
class CybersecurityLearnershipsPage extends StatelessWidget {
  const CybersecurityLearnershipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LearnershipEnrollmentPage(
      embedMode: false,
      initialSpecialization: null,
      categoryFilter: 'Cybersecurity',
      title: 'Cybersecurity Learnerships',
      subtitle: 'Build your career in digital security',
    );
  }
}
