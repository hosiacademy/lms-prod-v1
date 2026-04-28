import 'package:flutter/material.dart';

enum UserRole { student, instructor, admin }

class RoleBasedPortalCard extends StatelessWidget {
  final UserRole role;
  final VoidCallback onEnter;
  final bool isCurrent;

  const RoleBasedPortalCard({
    super.key,
    required this.role,
    required this.onEnter,
    this.isCurrent = false,
  });

  String get _title {
    switch (role) {
      case UserRole.student:
        return 'Student Portal';
      case UserRole.instructor:
        return 'Instructor Portal';
      case UserRole.admin:
        return 'Admin Portal';
    }
  }

  IconData get _icon {
    switch (role) {
      case UserRole.student:
        return Icons.school;
      case UserRole.instructor:
        return Icons.create;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: isCurrent ? 8 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isCurrent ? colors.primaryContainer : colors.surface,
      child: InkWell(
        onTap: onEnter,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _icon,
                size: 48,
                color: isCurrent ? colors.onPrimaryContainer : colors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                _title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color:
                      isCurrent ? colors.onPrimaryContainer : colors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isCurrent ? 'Current Role' : 'Switch to this role',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isCurrent
                      ? colors.onPrimaryContainer.withValues(alpha: 0.8)
                      : colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
