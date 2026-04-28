// lib/src/presentation/pages/onboarding/ai_blockchain_learnerships/ai_blockchain_learnerships_page.dart
import 'package:flutter/material.dart';
import '../../learnerships/learnership_enrollment_page.dart';

/// AI & Blockchain Learnerships Page
/// Shows ONLY learnerships with category = 'AI & Blockchain'
class AIBlockchainLearnershipsPage extends StatelessWidget {
  const AIBlockchainLearnershipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LearnershipEnrollmentPage(
      embedMode: false,
      initialSpecialization: null,
      categoryFilter: 'AI & Blockchain',  // Must match backend category exactly
      title: 'AI & Blockchain Learnerships',
      subtitle: 'Master the future of technology',
    );
  }
}
