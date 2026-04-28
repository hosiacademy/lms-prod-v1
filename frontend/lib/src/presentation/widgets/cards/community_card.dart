import 'package:flutter/material.dart';

class CommunityCard extends StatelessWidget {
  final String title;
  final String members;
  final String lastActive;
  final VoidCallback onJoin;

  const CommunityCard({
    super.key,
    required this.title,
    required this.members,
    required this.lastActive,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text('Members: ', style: TextStyle(color: Colors.grey[700])),
            Text('Last active: ', style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: onJoin,
                child: const Text('Join'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
