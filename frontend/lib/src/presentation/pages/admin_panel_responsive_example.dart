/// Example Admin Panel using Responsive Design System
/// 
/// This demonstrates how to create responsive tables that show as:
/// - Card list on mobile (< 600px)
/// - Data table on desktop (≥ 1024px)

import 'package:flutter/material.dart';
import '../../core/utils/utils.dart';
import '../../core/theme/theme.dart';
import '../widgets/responsive/responsive_system.dart';

class AdminPanelResponsiveExample extends StatefulWidget {
  const AdminPanelResponsiveExample({Key? key}) : super(key: key);

  @override
  State<AdminPanelResponsiveExample> createState() =>
      _AdminPanelResponsiveExampleState();
}

class _AdminPanelResponsiveExampleState
    extends State<AdminPanelResponsiveExample> {
  // Sample data
  final students = [
    {
      'id': '001',
      'name': 'Alice Johnson',
      'email': 'alice@example.com',
      'course': 'Flutter Basics',
      'status': 'Active',
      'progress': 75,
    },
    {
      'id': '002',
      'name': 'Bob Smith',
      'email': 'bob@example.com',
      'course': 'Advanced Dart',
      'status': 'Inactive',
      'progress': 30,
    },
    {
      'id': '003',
      'name': 'Carol White',
      'email': 'carol@example.com',
      'course': 'Web Development',
      'status': 'Active',
      'progress': 100,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students Admin'),
        elevation: 0,
      ),
      body: ResponsiveBuilder(
        mobile: (context) => _buildMobileList(context),
        desktop: (context) => _buildDesktopTable(context),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MOBILE VIEW: Card List
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMobileList(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppDesignSystem.md),
            child: ResponsiveText(
              '${students.length} Students',
              baseStyle: TextStyle(
                fontSize: ResponsiveHelper.h3(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: students.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: AppDesignSystem.md),
            itemBuilder: (context, index) {
              final student = students[index];
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDesignSystem.md,
                ),
                child: ResponsiveCard(
                  child: Padding(
                    padding: EdgeInsets.all(AppDesignSystem.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ResponsiveText(
                                student['name'] as String,
                                baseStyle: TextStyle(
                                  fontSize: ResponsiveHelper.body(context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppDesignSystem.sm,
                                vertical: AppDesignSystem.xs,
                              ),
                              decoration: BoxDecoration(
                                color: student['status'] == 'Active'
                                    ? AppTheme.successGreen
                                    : Colors.grey,
                                borderRadius:
                                    BorderRadius.circular(AppDesignSystem.radiusMD),
                              ),
                              child: ResponsiveText(
                                student['status'] as String,
                                baseStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: AppDesignSystem.sm),

                        // Email
                        ResponsiveText(
                          student['email'] as String,
                          baseStyle: TextStyle(
                            fontSize: ResponsiveHelper.caption(context),
                            color: Colors.grey[600],
                          ),
                        ),

                        SizedBox(height: AppDesignSystem.md),

                        // Course
                        ResponsiveText(
                          'Course: ${student['course']}',
                          baseStyle: TextStyle(
                            fontSize: ResponsiveHelper.caption(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        SizedBox(height: AppDesignSystem.sm),

                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppDesignSystem.radiusSM,
                          ),
                          child: LinearProgressIndicator(
                            value: (student['progress'] as int) / 100,
                            minHeight: 6,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.hosiPeach,
                            ),
                          ),
                        ),

                        SizedBox(height: AppDesignSystem.sm),

                        ResponsiveText(
                          '${student['progress']}% Complete',
                          baseStyle: TextStyle(
                            fontSize: ResponsiveHelper.caption(context),
                            color: Colors.grey[600],
                          ),
                        ),

                        SizedBox(height: AppDesignSystem.md),

                        // Action buttons
                        ResponsiveFlexRow(
                          children: [
                            (
                              child: ResponsiveButton(
                                label: 'View',
                                variant: ButtonVariant.outline,
                                onPressed: () {},
                              ),
                              flex: 50,
                            ),
                            (
                              child: ResponsiveButton(
                                label: 'Edit',
                                variant: ButtonVariant.primary,
                                onPressed: () {},
                              ),
                              flex: 50,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: AppDesignSystem.lg),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DESKTOP VIEW: Data Table
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDesktopTable(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(AppDesignSystem.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              '${students.length} Students',
              baseStyle: TextStyle(
                fontSize: ResponsiveHelper.h2(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppDesignSystem.lg),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(
                    label: ResponsiveText(
                      'Name',
                      baseStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveHelper.body(context),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: ResponsiveText(
                      'Email',
                      baseStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveHelper.body(context),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: ResponsiveText(
                      'Course',
                      baseStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveHelper.body(context),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: ResponsiveText(
                      'Progress',
                      baseStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveHelper.body(context),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: ResponsiveText(
                      'Status',
                      baseStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveHelper.body(context),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: ResponsiveText(
                      'Actions',
                      baseStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveHelper.body(context),
                      ),
                    ),
                  ),
                ],
                rows: students
                    .map(
                      (student) => DataRow(
                        cells: [
                          DataCell(
                            ResponsiveText(
                              student['name'] as String,
                              baseStyle: TextStyle(
                                fontSize: ResponsiveHelper.body(context),
                              ),
                            ),
                          ),
                          DataCell(
                            ResponsiveText(
                              student['email'] as String,
                              baseStyle: TextStyle(
                                fontSize: ResponsiveHelper.body(context),
                              ),
                            ),
                          ),
                          DataCell(
                            ResponsiveText(
                              student['course'] as String,
                              baseStyle: TextStyle(
                                fontSize: ResponsiveHelper.body(context),
                              ),
                            ),
                          ),
                          DataCell(
                            ResponsiveText(
                              '${student['progress']}%',
                              baseStyle: TextStyle(
                                fontSize: ResponsiveHelper.body(context),
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppDesignSystem.sm,
                                vertical: AppDesignSystem.xs,
                              ),
                              decoration: BoxDecoration(
                                color: student['status'] == 'Active'
                                    ? AppTheme.successGreen
                                    : Colors.grey,
                                borderRadius: BorderRadius.circular(
                                  AppDesignSystem.radiusMD,
                                ),
                              ),
                              child: ResponsiveText(
                                student['status'] as String,
                                baseStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () {},
                                  child: const Text('View'),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text('Edit'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// RESPONSIVE PATTERN: TABLE/LIST SWITCH
// ─────────────────────────────────────────────────────────────────────────
//
// This example uses ResponsiveBuilder to show different layouts:
//
// MOBILE (< 600px):
// - Card-based list view
// - Full-width cards with all info
// - Action buttons for each item
// - Easy to scroll and read
//
// DESKTOP (≥ 1024px):
// - Traditional data table
// - Multiple columns visible at once
// - Horizontal scrolling if needed
// - More information density
//
// ─────────────────────────────────────────────────────────────────────────
// KEY RESPONSIVE TECHNIQUES
// ─────────────────────────────────────────────────────────────────────────
//
// 1. ResponsiveBuilder
//    - Switch between mobile and desktop
//    - Provides ideal UX for each screen size
//
// 2. ResponsiveCard
//    - Used for mobile card items
//    - Consistent padding and elevation
//
// 3. ResponsiveFlexRow
//    - Action buttons side-by-side on mobile
//    - Flex ratios for even distribution
//
// 4. ResponsiveText
//    - Scaling font sizes for readability
//    - Different sizes for different contexts
//
// 5. ResponsiveSpacer
//    - Consistent spacing in cards
//    - Responsive gaps between elements
//
// ─────────────────────────────────────────────────────────────────────────
