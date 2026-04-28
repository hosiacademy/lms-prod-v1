import 'package:flutter/material.dart';
import '../modals/partner_program_modal.dart';

class PartnerProgramCTA extends StatelessWidget {
  const PartnerProgramCTA({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 40),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[900]!, Colors.blue[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.blue[900]!.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.rocket_launch,
            color: Colors.cyanAccent,
            size: 48,
          ),
          const SizedBox(height: 24),
          const Text(
            'Join our Influencer Network',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Earn commissions by promoting world-class AI & Blockchain certifications through your social media handles and unique links.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blue[100],
              fontSize: 18,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const PartnerProgramModal(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.blue[900],
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Apply as an Influencer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BenefitIcon(icon: Icons.payments_outlined, label: 'Instant Commission'),
              const SizedBox(width: 32),
              _BenefitIcon(icon: Icons.auto_graph_outlined, label: 'Real-time Tracking'),
              const SizedBox(width: 32),
              _BenefitIcon(icon: Icons.share_outlined, label: 'Easy Sharing'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BenefitIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BenefitIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.cyanAccent.withOpacity(0.7), size: 20),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
