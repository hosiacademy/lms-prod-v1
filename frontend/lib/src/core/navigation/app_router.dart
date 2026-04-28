// lib/src/core/navigation/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/onboarding/onboarding_page.dart';
import '../../presentation/pages/dashboard/home_dashboard_page.dart';
import '../../presentation/pages/dashboard/student_dashboard.dart';
import '../../presentation/pages/dashboard/instructor_dashboard.dart';
import '../../presentation/pages/dashboard/admin_dashboard.dart';
import '../../presentation/pages/admin/payment_admin_page.dart';
import '../../presentation/pages/admin/marketing_admin_page.dart';
import '../../presentation/pages/admin/hr_admin_page.dart';
import '../../presentation/pages/admin/executive_admin_page.dart';
import '../../presentation/pages/admin/universal_admin_welcome_page.dart';
import '../../presentation/pages/instructor/start_session_page.dart';
import '../../presentation/pages/instructor/sessions_page.dart';
import '../../presentation/pages/instructor/recordings_page.dart';
import '../../presentation/pages/learnerships/learnership_enrollment_page.dart';
import '../../presentation/pages/industry_training/industry_training_enrollment_page.dart';
import '../../presentation/pages/payment/eft_payment_result_page.dart';
import 'package:frontend/src/presentation/blocs/course/corporate/combined_masterclass_page.dart';
import '../../presentation/pages/student_portal/course_catalog_page.dart';
import '../../presentation/pages/student_portal/wishlist_page.dart';
import '../../presentation/pages/student_portal/course_cart_page.dart';
import '../../presentation/pages/student_portal/student_portal_page.dart';
import '../../presentation/widgets/common/portal_welcome_screen.dart';

// Learnership category pages
import '../../presentation/pages/onboarding/cybersecurity_learnerships/cybersecurity_learnerships_page.dart';
import '../../presentation/pages/onboarding/ai_blockchain_learnerships/ai_blockchain_learnerships_page.dart';
import '../../presentation/pages/quotations/quotation_document_page.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Session flag — reset to false on every hard refresh (in-memory only)
// ──────────────────────────────────────────────────────────────────────────────

bool _splashShownThisSession = false;

// ──────────────────────────────────────────────────────────────────────────────
// Redirect Logic - Controls where user goes based on auth & splash seen
// ──────────────────────────────────────────────────────────────────────────────

Future<String?> _redirectLogic(
    BuildContext context, GoRouterState state) async {
  final prefs = await SharedPreferences.getInstance();
  final isAuthenticated = prefs.getBool('is_authenticated') ?? false;
  final userRole = prefs.getString('user_role');
  final currentPath = state.uri.toString();

  print(
      '🔀 Router redirect: path=$currentPath, authenticated=$isAuthenticated, role=$userRole');

  // 0. Always show splash once per session (handles hard refresh).
  //    Authenticated users will be redirected to their dashboard after splash.
  if (!_splashShownThisSession) {
    if (currentPath == '/splash') {
      _splashShownThisSession = true;
      return null; // allow /splash to render
    }
    print('🚀 First load — redirecting to splash');
    return '/splash';
  }

  // 1. Allow navigation to splash and public pages regardless of auth status
  if (currentPath == '/splash' ||
      currentPath == '/onboarding' ||
      currentPath.startsWith('/combined-masterclass') ||
      currentPath.startsWith('/learnerships') ||
      currentPath.startsWith('/enroll/') ||  // NEW: Allow learnership category routes
      currentPath == '/industry-training' ||
      currentPath == '/catalog' || // Course catalog is publicly browseable
      currentPath == '/register' ||
      currentPath == '/login' ||
      currentPath.startsWith('/quotations/view/') || // NEW: Allow public quotation view
      currentPath.startsWith('/welcome/')) {
    // Allow welcome screens
    print('✅ All public page access: $currentPath');
    return null;
  }

  // 2. If NOT authenticated and trying to access protected routes → go to onboarding
  if (!isAuthenticated) {
    print('⛔ Redirecting unauthenticated user to onboarding');
    return '/onboarding';
  }

  // 3. If authenticated but on root path '/', redirect to role-specific dashboard
  if (currentPath == '/' && userRole != null) {
    final roleBasedPath = _getRoleBasedPath(userRole);
    print('🎯 Redirecting to role-based dashboard: $roleBasedPath');
    return roleBasedPath;
  }

  // 4. Validate user has permission for role-specific routes
  if (currentPath.startsWith('/admin/')) {
    final List<String> adminRoles = [
      'admin', 
      'payment_admin', 
      'marketing_admin',
      'hr_admin', 
      'executive_admin',
      'payment_sales_marketing_admin'
    ];
    
    if (!adminRoles.contains(userRole)) {
      print('⛔ Access denied: Non-admin trying to access admin route');
      return _getRoleBasedPath(userRole ?? 'learner');
    }
  }

  if (currentPath.startsWith('/instructor/') &&
      userRole != 'instructor' &&
      userRole != 'admin') {
    print('⛔ Access denied: Non-instructor trying to access instructor route');
    return _getRoleBasedPath(userRole ?? 'learner');
  }

  // 5. No redirect needed
  return null;
}

/// Get the correct dashboard path based on user role
String _getRoleBasedPath(String role) {
  switch (role) {
    case 'admin':
      return '/admin/dashboard';
    case 'payment_admin':
      return '/admin/payments';
    case 'marketing_admin':
      return '/admin/marketing';
    case 'payment_sales_marketing_admin':
      return '/admin/payments'; // Unified role defaults to payments for now
    case 'hr_admin':
      return '/admin/hr';
    case 'executive_admin':
      return '/admin/executive';
    case 'instructor':
    case 'facilitator':
      return '/instructor/dashboard';
    case 'learner':
    default:
      return '/student/dashboard';
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Error Page (404 / Not Found)
// ──────────────────────────────────────────────────────────────────────────────

Widget _errorBuilder(BuildContext context, GoRouterState state) {
  return Scaffold(
    appBar: AppBar(title: const Text('Not Found')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Page not found: ${state.uri}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Go to Dashboard'),
          ),
        ],
      ),
    ),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// Router Configuration
// ──────────────────────────────────────────────────────────────────────────────

final GoRouter router = GoRouter(
  initialLocation: '/splash',
  redirect: _redirectLogic,
  errorBuilder: _errorBuilder,
  debugLogDiagnostics: true,
  routes: [
    // Splash screen — shown once on every app load, then navigates to onboarding
    GoRoute(
      path: '/splash',
      name: 'splash',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const SplashPage(),
      ),
    ),

    // Onboarding (landing page)
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const OnboardingPage(),
      ),
    ),

    // Main Dashboard (protected - home base) - Role-based router
    GoRoute(
      path: '/',
      name: 'home',
      pageBuilder: (context, state) {
        // Fallback router - will be redirected by _redirectLogic to role-specific path
        return MaterialPage(
          key: ValueKey('home_${DateTime.now().millisecondsSinceEpoch}'),
          child: const HomeDashboardPage(),
        );
      },
    ),

    // ──────────────────────────────────────────────────────────────
    // Portal Welcome Screens (shown after login)
    // ──────────────────────────────────────────────────────────────
    GoRoute(
      path: '/welcome/student',
      name: 'welcome-student',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: Stack(
          children: [
            const StudentDashboard(),
            PortalWelcomeScreen(
              portalName: 'Student Portal',
              userFirstName: state.extra as String? ?? 'Student',
              primaryColor: Theme.of(context).colorScheme.primary,
              onComplete: () => context.go('/student/dashboard'),
            ),
          ],
        ),
      ),
    ),
    GoRoute(
      path: '/welcome/instructor',
      name: 'welcome-instructor',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: Stack(
          children: [
            const InstructorDashboard(),
            PortalWelcomeScreen(
              portalName: 'Instructor Portal',
              userFirstName: state.extra as String? ?? 'Instructor',
              primaryColor: Colors.purple,
              onComplete: () => context.go('/instructor/dashboard'),
            ),
          ],
        ),
      ),
    ),
    GoRoute(
      path: '/welcome/admin',
      name: 'welcome-admin',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: Stack(
          children: [
            const AdminDashboard(),
            PortalWelcomeScreen(
              portalName: 'Admin Portal',
              userFirstName: state.extra as String? ?? 'Admin',
              primaryColor: Colors.red,
              onComplete: () => context.go('/admin/dashboard'),
            ),
          ],
        ),
      ),
    ),
    GoRoute(
      path: '/welcome/payment-admin',
      name: 'welcome-payment-admin',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: Stack(
          children: [
            const PaymentAdminPage(),
            PortalWelcomeScreen(
              portalName: 'Payment Admin Portal',
              userFirstName: state.extra as String? ?? 'Payment Admin',
              primaryColor: Colors.teal,
              onComplete: () => context.go('/admin/payments'),
            ),
          ],
        ),
      ),
    ),
    GoRoute(
      path: '/welcome/marketing-admin',
      name: 'welcome-marketing-admin',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: Stack(
          children: [
            const MarketingAdminPage(),
            PortalWelcomeScreen(
              portalName: 'Marketing Admin Portal',
              userFirstName: state.extra as String? ?? 'Marketing Admin',
              primaryColor: Colors.orange,
              onComplete: () => context.go('/admin/marketing'),
            ),
          ],
        ),
      ),
    ),
    GoRoute(
      path: '/welcome/hr-admin',
      name: 'welcome-hr-admin',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: Stack(
          children: [
            const HRAdminPage(),
            PortalWelcomeScreen(
              portalName: 'HR Admin Portal',
              userFirstName: state.extra as String? ?? 'HR Admin',
              primaryColor: Colors.blueAccent,
              onComplete: () => context.go('/admin/hr'),
            ),
          ],
        ),
      ),
    ),
    GoRoute(
      path: '/welcome/universal',
      name: 'welcome-universal',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: UniversalAdminWelcomePage(
          userName: state.extra as String? ?? 'Universal Admin',
        ),
      ),
    ),
    GoRoute(
      path: '/welcome/executive-admin',
      name: 'welcome-executive-admin',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: Stack(
          children: [
            const ExecutiveAdminPage(),
            PortalWelcomeScreen(
              portalName: 'Executive Portal',
              userFirstName: state.extra as String? ?? 'Executive',
              primaryColor: Colors.indigo,
              onComplete: () => context.go('/admin/executive'),
            ),
          ],
        ),
      ),
    ),

    // ──────────────────────────────────────────────────────────────
    // Role-Specific Dashboard Routes (Protected)
    // ──────────────────────────────────────────────────────────────
    GoRoute(
      path: '/student/dashboard',
      name: 'student-dashboard',
      pageBuilder: (context, state) => MaterialPage(
        key: ValueKey('learner_${DateTime.now().millisecondsSinceEpoch}'),
        child: const StudentDashboard(),
      ),
    ),
    GoRoute(
      path: '/instructor/dashboard',
      name: 'instructor-dashboard',
      pageBuilder: (context, state) => MaterialPage(
        key: ValueKey('instructor_${DateTime.now().millisecondsSinceEpoch}'),
        child: const InstructorDashboard(),
      ),
    ),
    GoRoute(
      path: '/admin/dashboard',
      name: 'admin-dashboard',
      pageBuilder: (context, state) => MaterialPage(
        key: ValueKey('admin_${DateTime.now().millisecondsSinceEpoch}'),
        child: const AdminDashboard(),
      ),
    ),
    GoRoute(
      path: '/admin/payments',
      name: 'payment-admin-dashboard',
      pageBuilder: (context, state) => MaterialPage(
        key: ValueKey('payment_admin_${DateTime.now().millisecondsSinceEpoch}'),
        child: const PaymentAdminPage(),
      ),
    ),
    GoRoute(
      path: '/admin/marketing',
      name: 'marketing-admin-dashboard',
      pageBuilder: (context, state) => MaterialPage(
        key: ValueKey('marketing_admin_${DateTime.now().millisecondsSinceEpoch}'),
        child: const MarketingAdminPage(),
      ),
    ),
    GoRoute(
      path: '/admin/hr',
      name: 'hr-admin-dashboard',
      pageBuilder: (context, state) => MaterialPage(
        key: ValueKey('hr_admin_${DateTime.now().millisecondsSinceEpoch}'),
        child: const HRAdminPage(),
      ),
    ),
    GoRoute(
      path: '/admin/executive',
      name: 'executive-admin-dashboard',
      pageBuilder: (context, state) => MaterialPage(
        key: ValueKey(
            'executive_admin_${DateTime.now().millisecondsSinceEpoch}'),
        child: const ExecutiveAdminPage(),
      ),
    ),

    // ──────────────────────────────────────────────────────────────
    // Combined Masterclass Page (from onboarding overlay)
    // ──────────────────────────────────────────────────────────────
    GoRoute(
      path: '/combined-masterclass',
      name: 'combined-masterclass',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const CombinedMasterclassPage(),
      ),
    ),

    // ──────────────────────────────────────────────────────────────
    // Studentship Programme Routes
    // ──────────────────────────────────────────────────────────────
    GoRoute(
      path: '/learnerships',
      name: 'learnerships',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const LearnershipEnrollmentPage(),
      ),
    ),
    GoRoute(
      path: '/learnerships/:role',
      name: 'learnerships-role',
      pageBuilder: (context, state) {
        final role = state.pathParameters['role'];
        return MaterialPage(
          key: state.pageKey,
          child: Scaffold(
            appBar: AppBar(title: Text('Learnerships - ${role ?? "All"}')),
            body: Center(
              child: Text('Learnership Programme for $role - Coming Soon'),
            ),
          ),
        );
      },
    ),

    // ──────────────────────────────────────────────────────────────
    // Learnership Category Routes (from onboarding)
    // ──────────────────────────────────────────────────────────────
    GoRoute(
      path: '/enroll/learnerships',
      name: 'enroll-learnerships',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const AIBlockchainLearnershipsPage(),
      ),
    ),
    GoRoute(
      path: '/enroll/cybersecurity',
      name: 'enroll-cybersecurity',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const CybersecurityLearnershipsPage(),
      ),
    ),
    GoRoute(
      path: '/enroll/ai-blockchain',
      name: 'enroll-ai-blockchain',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const AIBlockchainLearnershipsPage(),
      ),
    ),

    // ──────────────────────────────────────────────────────────────
    // Industry & Role Based Training Routes
    // ──────────────────────────────────────────────────────────────
    GoRoute(
      path: '/industry-training',
      name: 'industry-training',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const IndustryTrainingEnrollmentPage(),
      ),
    ),

    // ──────────────────────────────────────────────────────────────
    // Student Portal Routes
    // ──────────────────────────────────────────────────────────────
    GoRoute(
      path: '/courses',
      name: 'courses',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const StudentPortalPage(userName: 'Student', initialTabIndex: 1),
      ),
    ),
    GoRoute(
      path: '/progress',
      name: 'progress',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const StudentPortalPage(userName: 'Student', initialTabIndex: 3),
      ),
    ),
    GoRoute(
      path: '/discussions',
      name: 'discussions',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: Scaffold(
          appBar: AppBar(title: const Text('Discussions')),
          body: const Center(child: Text('Forum / Discussions')),
        ),
      ),
    ),

    // ──────────────────────────────────────────────────────────────
    // Course Catalog & Shopping Features
    // ──────────────────────────────────────────────────────────────
    GoRoute(
      path: '/catalog',
      name: 'catalog',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const CourseCatalogPage(),
      ),
    ),
    GoRoute(
      path: '/wishlist',
      name: 'wishlist',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const WishlistPage(),
      ),
    ),
    GoRoute(
      path: '/cart',
      name: 'cart',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const CourseCartPage(),
      ),
    ),

    // ──────────────────────────────────────────────────────────────
    // EFT Payment Result Page
    // ──────────────────────────────────────────────────────────────
    GoRoute(
      path: '/eft-payment-result',
      name: 'eft-payment-result',
      pageBuilder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        return MaterialPage(
          key: state.pageKey,
          child: EftPaymentResultPage(
            reference: args?['reference'] as String,
            programId: args?['programId'] as String,
            programType: args?['programType'] as String,
            amount: (args?['amount'] as num).toDouble(),
            currency: args?['currency'] as String,
            programTitle: args?['programTitle'] as String,
          ),
        );
      },
    ),

    // ──────────────────────────────────────────────────────────────
    // Instructor BBB (BigBlueButton) Routes
    // ──────────────────────────────────────────────────────────────
    GoRoute(
      path: '/instructor/start-session',
      name: 'instructor-start-session',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const StartSessionPage(),
      ),
    ),
    GoRoute(
      path: '/instructor/sessions',
      name: 'instructor-sessions',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const SessionsPage(),
      ),
    ),
    GoRoute(
      path: '/instructor/recordings',
      name: 'instructor-recordings',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const RecordingsPage(),
      ),
    ),

    // ──────────────────────────────────────────────────────────────
    // Instructor / Facilitator / Admin Routes
    // ──────────────────────────────────────────────────────────────
    GoRoute(
      path: '/create-course',
      name: 'create-course',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: Scaffold(
          appBar: AppBar(title: const Text('Create Course')),
          body: const Center(child: Text('Course creation interface')),
        ),
      ),
    ),
    GoRoute(
      path: '/students',
      name: 'students',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: Scaffold(
          appBar: AppBar(title: const Text('My Students')),
          body: const Center(child: Text('Learner management')),
        ),
      ),
    ),
    GoRoute(
      path: '/assessments',
      name: 'assessments',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: Scaffold(
          appBar: AppBar(title: const Text('Assessments')),
          body: const Center(child: Text('Assessment management')),
        ),
      ),
    ),
    GoRoute(
      path: '/users',
      name: 'users',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: Scaffold(
          appBar: AppBar(title: const Text('Manage Users')),
          body: const Center(child: Text('User management')),
        ),
      ),
    ),
    GoRoute(
      path: '/analytics',
      name: 'analytics',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: Scaffold(
          appBar: AppBar(title: const Text('Analytics')),
          body: const Center(child: Text('Analytics dashboard')),
        ),
      ),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: const Center(child: Text('System / User settings')),
        ),
      ),
    ),

    // ──────────────────────────────────────────────────────────────
    // Auth Routes
    // ──────────────────────────────────────────────────────────────
    GoRoute(
      path: '/register',
      name: 'register',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final courseId = extra?['courseId'] as String? ?? 'general';
        return MaterialPage(
          key: state.pageKey,
          child: RegisterPage(courseId: courseId),
        );
      },
    ),
    
    // ──────────────────────────────────────────────────────────────
    // Public Quotation Document View
    // ──────────────────────────────────────────────────────────────
    GoRoute(
      path: '/quotations/view/:number',
      name: 'quotation-view',
      pageBuilder: (context, state) {
        final number = state.pathParameters['number'] ?? '';
        return MaterialPage(
          key: state.pageKey,
          child: QuotationDocumentPage(quotationNumber: number),
        );
      },
    ),
  ],
);
