/// Example Dashboard Page using Responsive Design System
/// 
/// This demonstrates how to use the new responsive system to create
/// a dashboard that works on mobile, tablet, and desktop.
///
/// To use this in your app:
/// 1. Replace existing dashboard_page.dart with this pattern
/// 2. Update imports to match your app structure
/// 3. Add your business logic (state management, API calls, etc.)

import 'package:flutter/material.dart';
import '../../core/utils/utils.dart';
import '../../core/theme/theme.dart';
import '../widgets/responsive/responsive_system.dart';

class DashboardResponsiveExample extends StatefulWidget {
  const DashboardResponsiveExample({Key? key}) : super(key: key);

  @override
  State<DashboardResponsiveExample> createState() =>
      _DashboardResponsiveExampleState();
}

class _DashboardResponsiveExampleState extends State<DashboardResponsiveExample> {
  // ─────────────────────────────────────────────────────────────────────────
  // RESPONSIVE EXAMPLE: Dashboard with Cards Grid
  // ─────────────────────────────────────────────────────────────────────────
  // 
  // This shows how to create a responsive dashboard using ResponsiveGrid.
  // 
  // Breakpoints:
  // - Mobile (< 600px): 1 column
  // - Tablet (600-1024px): 2 columns
  // - Desktop (≥ 1024px): 3 columns

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
      ),
      body: ResponsiveContainer(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Page Header
              Padding(
                padding: EdgeInsets.all(ResponsiveHelper.padding(context)),
                child: ResponsiveText(
                  'Welcome Back',
                  baseStyle: TextStyle(
                    fontSize: ResponsiveHelper.h1(context),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.hosiMidnight,
                  ),
                ),
              ),

              // Responsive Grid of Dashboard Cards
              ResponsiveGrid(
                mobileColumns: 1,
                tabletColumns: 2,
                desktopColumns: 3,
                mainAxisSpacing: AppDesignSystem.lg,
                crossAxisSpacing: AppDesignSystem.lg,
                padding: EdgeInsets.all(AppDesignSystem.md),
                children: [
                  _buildDashboardCard(
                    context,
                    icon: Icons.school,
                    title: 'Courses',
                    value: '12',
                    color: AppTheme.hosiPeach,
                  ),
                  _buildDashboardCard(
                    context,
                    icon: Icons.assignment_turned_in,
                    title: 'Completed',
                    value: '8',
                    color: AppTheme.successGreen,
                  ),
                  _buildDashboardCard(
                    context,
                    icon: Icons.pending_actions,
                    title: 'In Progress',
                    value: '4',
                    color: AppTheme.hosiBrown,
                  ),
                ],
              ),

              SizedBox(height: AppDesignSystem.lg),

              // Recent Activity Section
              Padding(
                padding: EdgeInsets.all(AppDesignSystem.md),
                child: ResponsiveSectionHeader(
                  title: 'Recent Activity',
                  onActionPressed: () {
                    // Navigate to activity page
                  },
                ),
              ),

              // Recent Activity List
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDesignSystem.md,
                ),
                child: _buildActivityList(context),
              ),

              SizedBox(height: AppDesignSystem.xl),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER METHODS
  // ─────────────────────────────────────────────────────────────────────────

  /// Build a dashboard card widget
  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return ResponsiveCard(
      child: Padding(
        padding: EdgeInsets.all(AppDesignSystem.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and Title Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ResponsiveText(
                  title,
                  baseStyle: TextStyle(
                    fontSize: ResponsiveHelper.body(context),
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                Icon(
                  icon,
                  size: ResponsiveHelper.iconSize(context),
                  color: color,
                ),
              ],
            ),

            SizedBox(height: AppDesignSystem.md),

            // Value
            ResponsiveText(
              value,
              baseStyle: TextStyle(
                fontSize: ResponsiveHelper.h2(context),
                fontWeight: FontWeight.bold,
                color: AppTheme.hosiMidnight,
              ),
            ),

            SizedBox(height: AppDesignSystem.sm),

            // Change indicator (example)
            ResponsiveText(
              '+2 this week',
              baseStyle: TextStyle(
                fontSize: ResponsiveHelper.caption(context),
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build activity list
  Widget _buildActivityList(BuildContext context) {
    final activities = [
      {
        'title': 'Completed Course: Flutter Basics',
        'time': '2 hours ago',
        'icon': Icons.check_circle,
      },
      {
        'title': 'Started: Advanced Dart',
        'time': '1 day ago',
        'icon': Icons.play_circle,
      },
      {
        'title': 'Assignment submitted: Project 1',
        'time': '3 days ago',
        'icon': Icons.upload_file,
      },
    ];

    return Column(
      children: List.generate(
        activities.length,
        (index) {
          final activity = activities[index];
          return ResponsiveListItem(
            avatar: Icon(
              activity['icon'] as IconData,
              color: AppTheme.hosiPeach,
              size: ResponsiveHelper.iconSize(context) * 0.8,
            ),
            title: activity['title'] as String,
            subtitle: activity['time'] as String,
            onTap: () {
              // Handle tap
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// RESPONSIVE PATTERN EXPLANATION
// ─────────────────────────────────────────────────────────────────────────
//
// This example demonstrates several responsive patterns:
//
// 1. RESPONSIVE GRID
//    ResponsiveGrid automatically changes columns based on screen size:
//    - Mobile: 1 column (full width)
//    - Tablet: 2 columns
//    - Desktop: 3 columns
//
// 2. RESPONSIVE CONTAINER
//    ResponsiveContainer constrains content width on large screens
//    and prevents content from being too wide on desktop.
//
// 3. RESPONSIVE TEXT
//    ResponsiveText uses ResponsiveHelper.h1(), h2(), body() to scale
//    font sizes appropriately at each breakpoint.
//
// 4. RESPONSIVE SPACING
//    Uses AppDesignSystem constants (md, lg, xl) for consistent spacing
//    that works across all device sizes.
//
// 5. RESPONSIVE COMPONENTS
//    ResponsiveCard, ResponsiveListItem, ResponsiveSectionHeader all
//    automatically adapt sizing and spacing to screen size.
//
// ─────────────────────────────────────────────────────────────────────────
// TESTING CHECKLIST
// ─────────────────────────────────────────────────────────────────────────
//
// Test this page on:
// - Mobile (375px): Should show 1 column, full-width cards
// - Tablet (768px): Should show 2 columns, responsive padding
// - Desktop (1440px): Should show 3 columns, centered, max-width container
//
// Verify:
// - Text sizes are readable at all breakpoints
// - Cards stack properly on mobile
// - Spacing is consistent
// - All icons visible
// - No overflow/horizontal scroll
//
// ─────────────────────────────────────────────────────────────────────────
