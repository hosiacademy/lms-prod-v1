// lib/src/presentation/widgets/enrollment/enrollment_type_selection.dart

import 'package:flutter/material.dart';

/// Enrollment Type Selection Widget
/// Allows users to choose between Individual or Company enrollment
class EnrollmentTypeSelection extends StatefulWidget {
  final Function(String enrollmentType) onTypeSelected;
  final String trainingTitle;

  const EnrollmentTypeSelection({
    Key? key,
    required this.onTypeSelected,
    required this.trainingTitle,
  }) : super(key: key);

  @override
  State<EnrollmentTypeSelection> createState() =>
      _EnrollmentTypeSelectionState();
}

class _EnrollmentTypeSelectionState extends State<EnrollmentTypeSelection> {
  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.how_to_reg, color: colors.primary, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Enrollment Type',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.trainingTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: colors.onPrimaryContainer, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Select how you want to enroll in this learnership programme',
                      style: TextStyle(
                        color: colors.onPrimaryContainer,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Individual Enrollment Option
            _EnrollmentTypeCard(
              icon: Icons.person,
              title: 'Individual Enrollment',
              description: 'Enroll yourself as an individual learner',
              features: [
                'Personal training certificate',
                'Self-paced learning',
                'Individual progress tracking',
                'One-time enrollment per programme',
              ],
              isSelected: _selectedType == 'individual',
              onTap: () => setState(() => _selectedType = 'individual'),
              colors: colors,
            ),
            const SizedBox(height: 16),

            // Company Enrollment Option
            _EnrollmentTypeCard(
              icon: Icons.business,
              title: 'Company/Corporate Enrollment',
              description: 'Enroll multiple employees from your organization',
              features: [
                'Bulk enrollment for employees',
                'Company-wide reporting',
                'Multiple cohorts supported',
                'Dedicated company contact point',
              ],
              isSelected: _selectedType == 'company',
              onTap: () => setState(() => _selectedType = 'company'),
              colors: colors,
            ),
            const SizedBox(height: 24),

            // Continue Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _selectedType == null
                    ? null
                    : () => widget.onTypeSelected(_selectedType!),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continue'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnrollmentTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colors;

  const _EnrollmentTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isSelected ? colors.primary : colors.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? colors.primaryContainer.withValues(alpha: 0.3)
              : colors.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primary
                        : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color:
                        isSelected ? colors.onPrimary : colors.onSurface,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? colors.primary : colors.onSurface,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: colors.primary,
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check,
                        size: 16,
                        color: isSelected
                            ? colors.primary
                            : colors.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
