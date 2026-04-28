// lib/src/core/utils/course_icons.dart

import 'package:flutter/material.dart';

/// Course Icon Mapping
/// Provides consistent icons for different course types across the application
class CourseIcons {
  /// Get icon for a course name or specialization
  static IconData getIconForCourse(String courseName) {
    final lowerName = courseName.toLowerCase();

    // Data Science & Analytics
    if (lowerName.contains('data science') ||
        lowerName.contains('analytics') ||
        lowerName.contains('data analyst')) {
      return Icons.query_stats;
    }

    // AI & Machine Learning
    if (lowerName.contains('ai') ||
        lowerName.contains('artificial intelligence') ||
        lowerName.contains('machine learning') ||
        lowerName.contains('ml') ||
        lowerName.contains('deep learning')) {
      return Icons.psychology;
    }

    // Cloud Computing
    if (lowerName.contains('cloud') ||
        lowerName.contains('aws') ||
        lowerName.contains('azure') ||
        lowerName.contains('gcp')) {
      return Icons.cloud_outlined;
    }

    // Cybersecurity
    if (lowerName.contains('security') ||
        lowerName.contains('cybersecurity') ||
        lowerName.contains('cyber')) {
      return Icons.security;
    }

    // Software Development
    if (lowerName.contains('developer') ||
        lowerName.contains('development') ||
        lowerName.contains('programming') ||
        lowerName.contains('software') ||
        lowerName.contains('coding')) {
      return Icons.code;
    }

    // Web Development
    if (lowerName.contains('web') ||
        lowerName.contains('frontend') ||
        lowerName.contains('backend') ||
        lowerName.contains('fullstack')) {
      return Icons.web;
    }

    // Mobile Development
    if (lowerName.contains('mobile') ||
        lowerName.contains('android') ||
        lowerName.contains('ios') ||
        lowerName.contains('flutter')) {
      return Icons.phone_android;
    }

    // DevOps
    if (lowerName.contains('devops') ||
        lowerName.contains('ci/cd') ||
        lowerName.contains('deployment')) {
      return Icons.settings_applications;
    }

    // Blockchain
    if (lowerName.contains('blockchain') ||
        lowerName.contains('crypto') ||
        lowerName.contains('web3')) {
      return Icons.account_balance;
    }

    // Database
    if (lowerName.contains('database') ||
        lowerName.contains('sql') ||
        lowerName.contains('mongodb')) {
      return Icons.storage;
    }

    // Network
    if (lowerName.contains('network') ||
        lowerName.contains('cisco')) {
      return Icons.router;
    }

    // Project Management
    if (lowerName.contains('project management') ||
        lowerName.contains('agile') ||
        lowerName.contains('scrum')) {
      return Icons.dashboard;
    }

    // Business & Finance
    if (lowerName.contains('business') ||
        lowerName.contains('finance') ||
        lowerName.contains('accounting')) {
      return Icons.business_center;
    }

    // Design
    if (lowerName.contains('design') ||
        lowerName.contains('ui/ux') ||
        lowerName.contains('graphics')) {
      return Icons.design_services;
    }

    // Testing & QA
    if (lowerName.contains('testing') ||
        lowerName.contains('qa') ||
        lowerName.contains('quality assurance')) {
      return Icons.bug_report;
    }

    // Default icon
    return Icons.school;
  }

  /// Get color for a specialization category
  static Color getColorForSpecialization(String specialization, ColorScheme colors) {
    final lower = specialization.toLowerCase();

    if (lower.contains('data science')) {
      return colors.primary;
    } else if (lower.contains('ai') || lower.contains('cloud')) {
      return colors.secondary;
    } else if (lower.contains('security')) {
      return colors.error;
    } else {
      return colors.tertiary;
    }
  }

  /// Get icon for delivery mode
  static IconData getDeliveryModeIcon(String? deliveryMode) {
    switch (deliveryMode?.toLowerCase()) {
      case 'online':
        return Icons.computer;
      case 'in_person':
      case 'in-person':
        return Icons.location_on;
      case 'hybrid':
        return Icons.sync_alt;
      default:
        return Icons.sync_alt; // Default to hybrid
    }
  }
}
